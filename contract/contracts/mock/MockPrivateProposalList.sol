pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

import "../utils/proposal/Proposal.sol";
import "../utils/proposal/PrivateProposalList.sol";

contract MockPrivateProposalList {
  using PrivateProposalList for PrivateProposalList.Data;

  PrivateProposalList.Data _proposals;

  function exist(uint256 id) public view returns (bool) {
    return _proposals.exist(id);
  }

  function add(
    uint256 id,
    bytes32 hash)
  public returns (bool) {
    return _proposals.add(id, hash, msg.sender);
  }

  function getVotingCount() public view returns (uint256) {
    return _proposals.getVotingCount();
  }

  function getVotedCount() public view returns (uint256) {
    return _proposals.getVotedCount();
  }

  function getAllVotingTopicIds() public view returns (uint256[]) {
    return _proposals.getAllVotingTopicIds();
  }

  function getTopic(uint256 id) public view returns (Proposal.PrivateTopic) {
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

  function getVotedTopicIds(uint256 from, uint256 to) public view returns (uint256[] memory) {
    return _proposals.getVotedTopicIds(from, to);
  }
}
