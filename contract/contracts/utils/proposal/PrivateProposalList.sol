pragma solidity 0.4.24;
import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "./Proposal.sol";

/**
 * @dev 提案列表管理模块.
 */
library PrivateProposalList {
  using SafeMath for uint256;

  /**
    提案相关状态列表
   */
  struct StateList {
    // 投票中的提案索引
    uint256[] voting;
    // 已经表决的提案索引
    uint256[] voted;
    // 已经执行的提案索引
    uint256[] exetued;
  }

  /**
  所有提案列表
   */
  struct Data
  {
    // 所有提案列表: topic ID是关键字
    mapping(uint256 => Proposal.PrivateTopic) _topics;

    // 提案状态
    StateList _list;

    // 所有提案投票记录
    mapping(bytes32 => Proposal.VoteDetail) _voteDetails;

    // 按照提案ID的投票明细
    mapping(uint256 => bytes32[]) _voteIdxs;
  }

  function exist(Data storage self, uint256 id) internal view returns (bool) {
    if(self._topics[id].id == 0) return false;
    return (self._topics[id].id == id);
  }

  // 建立投票议题
  function add(
    Data storage self,
    uint256 id,
    bytes32 hash,
    address sponsor)
  internal returns (bool){

    if (exist(self, id)) {
      return false;
    }

    self._topics[id].id = id;
    self._topics[id].hash = hash;
    self._topics[id].sponsor = sponsor;
    self._topics[id].executed = false;
    self._topics[id].idx = self._list.voting.push(id).sub(1);

    return true;
  }

  // 等待表决提案数量
  function getVotingCount(Data storage self) internal view returns (uint256) {
    return self._list.voting.length;
  }
  // 已表决提案数量
  function getVotedCount(Data storage self) internal view returns (uint256) {
    return self._list.voted.length;
  }

  // 所有提案数量
  function count(Data storage self) internal view returns (uint256) {
    return self._list.voted.length + self._list.voting.length;
  }
  // 获得当前未决投票清单
  function getAllVotingTopicIds(Data storage self) internal view returns (uint256[]) {
    return self._list.voting;
  }

  function getTopic(Data storage self, uint256 id) internal view returns (Proposal.PrivateTopic) {
    return self._topics[id];
  }

  // 获得当前已决提案id
  function getVotedTopicIds(Data storage self, uint256 from, uint256 to) internal view returns (uint256[] memory) {
    require(to >= from, "index to must bigger than from");
    require(to < self._list.voted.length, "index to must smaller than voted count");

    uint256 len = 0;
    uint256 size = to.sub(from).add(1);
    uint256[] memory res = new uint256[](size);
    for (uint256 i = from; i <= to; i++) {
      res[len] = self._list.voted[i];
      len = len.add(1);
    }
    return res;
  }

  // 更新决议执行后的状态
  function submit(Data storage self, uint256 id) internal returns (bool) {
    if (!exist(self, id)) {
      return false;
    }
    // 已经被标记为完成的不再处理
    if (self._topics[id].executed) {
      return false;
    }

    // 修改全局的议题状态
    uint256 row2Del = self._topics[id].idx;
    uint256 key2Move = self._list.voting[self._list.voting.length.sub(1)];
    self._list.voting[row2Del] = key2Move;
    self._topics[key2Move].idx = row2Del;
    self._list.voting.length = self._list.voting.length.sub(1);

    // 设置议题结束 移动到已决议题索引中
    self._topics[id].executed = true;
    self._topics[id].idx = self._list.voted.push(id).sub(1);

    return true;
  }

  function existVote(Data storage self, bytes32 key) internal view returns (bool) {
    if(self._voteDetails[key].id == 0) return false;
    return (key == keccak256(abi.encodePacked(self._voteDetails[key].id, self._voteDetails[key].voter)));
  }

  // 处理投票明细信息
  function vote(
    Data storage self,
    uint256 id,
    uint256 timestamp,
    address voter,
    bool favor)
  internal returns (bool) {

    if (!exist(self, id)) {
      return false;
    }

    // 拒绝相同的投票内容,不同内容意味着revoke原先的投票
    bytes32 key = keccak256(abi.encodePacked(id, voter));
    if (existVote(self, key) && self._voteDetails[key].favor == favor) {
      return false;
    }

    self._voteDetails[key].id = id;
    self._voteDetails[key].timestamp = timestamp;
    self._voteDetails[key].voter = voter;
    self._voteDetails[key].favor = favor;
    self._voteDetails[key].idx = self._voteIdxs[id].push(key).sub(1);

    return true;
  }

  function getVoteIdxs(Data storage self, uint256 id) internal view returns (bytes32[]) {
    return self._voteIdxs[id];
  }

  // 前端的钱包想知道自己对议题有无投票，可以用topicId，钱包地址做一次keccak256运算得到key，检索是否有数据
  function getVoteDetail(Data storage self, bytes32 key) internal view returns (Proposal.VoteDetail) {
    return self._voteDetails[key];
  }

  // 获取议题所有投票明细
  function getVoteDetails(Data storage self, uint256 id) internal view returns (Proposal.VoteDetail[] memory) {
    uint256 len = self._voteIdxs[id].length;

    require(len > 0, "must have vote detail");

    Proposal.VoteDetail[] memory res = new Proposal.VoteDetail[](len);

    bytes32 key;
    for (uint256 i = 0; i < len; i++) {
      key = self._voteIdxs[id][i];
      res[i] = self._voteDetails[key];
    }
    return res;
  }
}