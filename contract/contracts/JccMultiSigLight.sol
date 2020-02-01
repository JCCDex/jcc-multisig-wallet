pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "jcc-solidity-utils/contracts/math/SafeMath.sol";
import "jcc-solidity-utils/contracts/utils/AddressUtils.sol";
import "./IMultiSig.sol";
import "./utils/proposal/Proposal.sol";
import "./utils/proposal/PublicProposalList.sol";

/**
 轻量版多签钱包
 成员和规则创建时建立并不再改变
 */
contract JccMultiSigLight is IMultiSig {
  using SafeMath for uint256;
  using AddressUtils for address;
  using PublicProposalList for PublicProposalList.Data;

  uint256 constant public MAX_OWNER_COUNT = 108;

  uint256 public required;
  address[] public owners;
  mapping (address => bool) public isOwner;

  PublicProposalList.Data _proposals;

  modifier validRequirement(uint _count, uint _required) {
    require(_count <= MAX_OWNER_COUNT && _required <= _count && _required != 0 && _count != 0, "parameter error");
    _;
  }

  constructor(address[] _owners, uint256 _required) validRequirement(_owners.length, _required) public {
    for (uint i = 0; i < _owners.length; i++) {
      require (!isOwner[_owners[i]] && !_owners[i].isZeroAddress(), "owner address invalid");
      isOwner[_owners[i]] = true;
    }
    // 恒定不修改
    owners = _owners;
    required = _required;
  }

  /**
    提案
    hash 由 keccak256 (to, value, data, salt)就算得出
    salt为0表示提案是公开的,不为0表示秘密提案，可以在链外交换
   */
  function suggest(bytes32 _hash) public returns (uint256 id) {
    require(isOwner[msg.sender] && !msg.sender.isZeroAddress(), "must be owner");

    uint256 _id = _proposals.count().add(1);

    // 初始提交明细信息置零
    require(_proposals.add(_id, _hash, msg.sender, address(0), 0, "0x0"), "add suggest fail");

    emit Suggestion(_id, msg.sender, _hash);

    return _id;
  }

  // 对提案进行批准
  function approve(uint256 _id) public {
    require(isOwner[msg.sender] && !msg.sender.isZeroAddress(), "must be owner");

    Proposal.VoteDetail memory exist = _proposals.getVoteDetail(keccak256(abi.encodePacked(_id, msg.sender)));
    require(!(exist.id == _id && exist.voter == msg.sender && exist.favor == true), "Don't approve again");

    require(_proposals.vote(_id, block.timestamp, msg.sender, true), "approve fail");

    emit Approval(_id, msg.sender);
  }

  // 撤销自己的批准
  function revokeApproval(uint256 _id) public {
    require(isOwner[msg.sender] && !msg.sender.isZeroAddress(), "must be owner");

    Proposal.VoteDetail memory exist = _proposals.getVoteDetail(keccak256(abi.encodePacked(_id, msg.sender)));
    require(!(exist.id == _id && exist.voter == msg.sender && exist.favor == false), "Don't revoke approval again");

    require(_proposals.vote(_id, block.timestamp, msg.sender, false), "revoke approve fail");

    emit ApprovalRevocation(_id, msg.sender);
  }

  /**
    执行批准的提案
    执行提案的细节内容来源有两种情况
    1. 来自公开的提案信息，有 reveal 函数提交，那么salt固定为0
    2. 来自链外的交换，那么要验证细节数据计算的hash是否一致，id是否存在，然后发起调用
    对于普通用户来说，这个接口人工阅读很费解，需要应用层进行形象化处理
   */
  function execute(uint256 _id, address _to, uint256 _value, bytes _data, uint256 _salt) public returns (bool success) {
    // require(isOwner[msg.sender] && !msg.sender.isZeroAddress(), "must be owner");
    require(_proposals.exist(_id), "suggestion does not exist");
    require(isApproved(_id), "suggestion is not approved");

    Proposal.PublicTopic memory _topic = _proposals.getTopic(_id);
    require(!_topic.core.executed, "suggestion have executed");

    bytes32 _hash = keccak256(abi.encodePacked(_to, _value, _data, _salt));
    require(_hash == _topic.core.hash, "hash is not correct");

    if (_to.call.value(_value)(_data)) {
      _proposals.submit(_id);
      emit Execution(_id, msg.sender, true);
      return true;
    }

    return false;
  }

  function() public payable {
    require(msg.value > 0, "can not receive 0");
  }

  /**
    公开提案明细信息，如果是私有流程，该函数不必调用，链外协调
    hash 由 keccak256(to, value, data, salt)计算得出，在公开流程中salt始终未0
   */
  function reveal(uint256 _id, address _to, uint256 _value, bytes _data) public {
    require(isOwner[msg.sender] && !msg.sender.isZeroAddress(), "must be owner");

    Proposal.PublicTopic memory _topic = _proposals.getTopic(_id);
    require(_id == _topic.core.id && msg.sender == _topic.core.sponsor, "topic must be exist");

    require(_proposals.update(_id, msg.sender, _to, _value, _data), "update topic fail");
    emit Revelation(_id, msg.sender, _to, _value, _data);
  }

  // 根据id获取提案hash
  function getHash(uint256 _id) public view returns (bytes32 hash) {
    Proposal.PublicTopic memory _topic = _proposals.getTopic(_id);
    return _topic.core.hash;
  }

  function getSuggestion(uint256 _id) public view returns (Proposal.PublicTopic memory topic) {
    return _proposals.getTopic(_id);
  }

  // 根据id获取批准状态
  function isApproved(uint256 _id) public view returns (bool approved) {
    uint256 _count = 0;
    Proposal.VoteDetail[] memory _details = _proposals.getVoteDetails(_id);
    for (uint256 i = 0; i < _details.length; i++) {
      if (_details[i].favor) {
        _count = _count.add(1);
      }
      if (_count >= required) {
        return true;
      }
    }

    return false;
  }

  // 根据id获取每个投票人的批准状态
  function isApprovedBy(uint256 _id, address _owner) public view returns (bool approved) {
    Proposal.VoteDetail memory _exist = _proposals.getVoteDetail(keccak256(abi.encodePacked(_id, _owner)));
    return _exist.favor;
  }

  function getOwners() public view returns (address[]) {
    return owners;
  }
}