/* eslint-disable indent */
/* eslint-disable semi */
/* eslint-disable no-undef */
const MockPrivateProposalList = artifacts.require('MockPrivateProposalList');

contract('PrivateProposalList', (accounts) => {
  let proposal;

  beforeEach(async () => {
    proposal = await MockPrivateProposalList.new();
  });

  it('PrivateProposalList test', async () => {
    // test exist
    let exist = await proposal.exist(1);
    assert.equal(exist, false);

    let timestamp = Date.now();
    await proposal.add(timestamp, '0xe60d3cf13ddccd273c26e72a25944fff34bfc3a446d7821139192a40cde6ba9b');

    let votingCount = await proposal.getVotingCount()
    assert.equal(votingCount, 1);
    let votedCount = await proposal.getVotedCount()
    assert.equal(votedCount, 0);

    timestamp = timestamp + 10;
    await proposal.add(timestamp, '0xe60d3cf13ddccd273c26e72a25944fff34bfc3a446d7821139192a40cde6ba9c');

    timestamp = timestamp + 10;
    await proposal.add(timestamp, '0xe60d3cf13ddccd273c26e72a25944fff34bfc3a446d7821139192a40cde6ba9d');
    // 重复一次，应该会不成功
    await proposal.add(timestamp, '0xe60d3cf13ddccd273c26e72a25944fff34bfc3a446d7821139192a40cde6ba9d');

    votingCount = await proposal.getVotingCount()
    assert.equal(votingCount, 3);

    let allIds = await proposal.getAllVotingTopicIds();
    assert.equal(allIds.length, 3);

    let topic = await proposal.getTopic(allIds[1]);
    assert.equal(topic.hash, '0xe60d3cf13ddccd273c26e72a25944fff34bfc3a446d7821139192a40cde6ba9c');

    // 测试投票
    await proposal.vote(allIds[0], Date.now(), true, { from: accounts[1] });
    let allDetail = await proposal.getVoteDetails(allIds[0]);
    assert.equal(allDetail.length, 1);

    await proposal.vote(allIds[0], Date.now(), true, { from: accounts[2] });
    await proposal.vote(allIds[0], Date.now(), true, { from: accounts[3] });
    await proposal.vote(allIds[0], Date.now(), false, { from: accounts[4] });
    await proposal.vote(allIds[0], Date.now(), false, { from: accounts[5] });

    let voteIdxs = await proposal.getVoteIdxs(allIds[0]);
    assert.equal(voteIdxs.length, 5)

    let voteDetail = await proposal.getVoteDetail(allIds[0], { from: accounts[4] });
    assert.equal(voteDetail.voter, accounts[4]);

    allDetail = await proposal.getVoteDetails(allIds[0]);
    assert.equal(allDetail[3].voter, accounts[4]);

    // 测试移动待决到已决
    await proposal.submit(allIds[0]);
    votingCount = await proposal.getVotingCount()
    assert.equal(votingCount, 2);
    votedCount = await proposal.getVotedCount()
    assert.equal(votedCount, 1);

    await proposal.vote(allIds[1], Date.now(), true, { from: accounts[1] });
    await proposal.vote(allIds[1], Date.now(), true, { from: accounts[2] });
    await proposal.vote(allIds[1], Date.now(), true, { from: accounts[3] });
    await proposal.vote(allIds[1], Date.now(), true, { from: accounts[4] });
    await proposal.vote(allIds[1], Date.now(), true, { from: accounts[5] });

    await proposal.submit(allIds[1]);
    votingCount = await proposal.getVotingCount()
    assert.equal(votingCount, 1);
    votedCount = await proposal.getVotedCount()
    assert.equal(votedCount, 2);

    let votedTopicIds = await proposal.getVotedTopicIds(0, votedCount - 1);
    assert.equal(votedTopicIds[0].toString(), allIds[0].toString());

    votedTopicIds = await proposal.getVotedTopicIds(1, 1);
    assert.equal(votedTopicIds[0].toString(), allIds[1].toString());
  });
});
