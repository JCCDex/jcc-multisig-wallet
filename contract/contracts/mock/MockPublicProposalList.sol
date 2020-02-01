pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "../utils/proposal/Proposal.sol";
import "../utils/proposal/PublicProposalList.sol";

contract MockPublicProposalList {
  using PublicProposalList for PublicProposalList.Data;

  PublicProposalList.Data _proposals;

  function exist(uint256 id) public view returns (bool) {
    return _proposals.exist(id);
  }

  function add(
    uint256 id,
    bytes32 hash,
    address to,
    uint256 value,
    bytes data)
  public returns (bool) {
    return _proposals.add(id, hash, msg.sender, to, value, data);
  }

  function getVotingCount() public view returns (uint256) {
    return _proposals.getVotingCount();
  }

  function getVotedCount() public view returns (uint256) {
    return _proposals.getVotedCount();
  }

  function count() public view returns (uint256) {
    return _proposals.count();
  }

  function getAllVotingTopicIds() public view returns (uint256[]) {
    return _proposals.getAllVotingTopicIds();
  }

  function getTopic(uint256 id) public view returns (Proposal.PublicTopic) {
    return _proposals.getTopic(id);
  }

  function vote(uint256 id, uint256 timestamp, bool favor) public returns (bool) {
    return _proposals.vote(id, timestamp, msg.sender, favor);
  }

  function getVoteIdxs(uint256 id) public view returns (bytes32[]) {
    return _proposals.getVoteIdxs(id);
  }

  function getVoteDetail(uint256 id) public view returns (Proposal.VoteDetail) {
    bytes32 key = keccak256(abi.encodePacked(id, msg.sender));
    return _proposals.getVoteDetail(key);
  }

  function getVoteDetails(uint256 id) public view returns (Proposal.VoteDetail[]) {
    return _proposals.getVoteDetails(id);
  }

  function submit(uint256 id) public returns (bool) {
    return _proposals.submit(id);
  }

  function update(
    uint256 id,
    address to,
    uint256 value,
    bytes data)
  public returns (bool) {
    return _proposals.update(id, msg.sender, to, value, data);
  }

  function getHash(
    address to,
    uint256 value,
    bytes data)
  public pure returns (bytes32, bytes) {
    bytes memory _data = abi.encodePacked(to, value, data, uint256(0));
    bytes32 _hash = keccak256 (_data);
    return (_hash, _data);
  }

  function getVotedTopicIds(uint256 from, uint256 to) public view returns (uint256[] memory) {
    return _proposals.getVotedTopicIds(from, to);
  }
}
