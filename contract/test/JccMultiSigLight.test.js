/* eslint-disable indent */
/* eslint-disable semi */
/* eslint-disable no-undef */
const JccMultiSigLight = artifacts.require('JccMultiSigLight');
const MAYAToken = artifacts.require('MAYAToken');
const Utils = require('jcc-ethereum-utils').Ethereum;
const BigNumber = require('bignumber.js');
const getTopicHash = require('./helpers/getTopicHash');
const zeroAccount = require('./helpers/zeroAccount');
const assertRevert = require('./helpers/assertRevert');
const timeTravel = require('./helpers/timeTravel');

contract('JccMultiSigLight', (accounts) => {
  let multiWallet;
  let maya;
  let owner1 = accounts[0];
  let owner2 = accounts[1];
  let owner3 = accounts[2];
  let owner4 = accounts[3];
  let owner5 = accounts[4];

  let mayaAdmin = accounts[5];

  let required = 3;

  beforeEach(async () => {
    multiWallet = await JccMultiSigLight.new([owner1, owner2, owner3, owner4, owner5], required, { from: owner1, gasLimit: 1000000 });
    maya = await MAYAToken.new(mayaAdmin, { from: mayaAdmin });
    await maya.transfer(multiWallet.address, web3.utils.toWei('200'), { from: mayaAdmin });
    // let b = await maya.balanceOf(multiWallet.address);
    // console.log(b.toString());
  });

  it('JccMultiSigLight create test', async () => {
    // 获取所有人
    let owners = await multiWallet.getOwners();
    assert.equal(owners.length, 5);
    let req = await multiWallet.required();
    assert.equal(req.toString(), '3');
  });

  it('JccMultiSigLight full public flow', async () => {
    /**
     * 构造一个交易，计算出hash，发起建议: 调用MAYA ERC20合约，向mayaAdmin转200个回去
     */
    let data = '0xa9059cbb000000000000000000000000' + Utils.filter0x(mayaAdmin).toLowerCase() + '00000000000000000000000000000000000000000000000ad78ebc5ac6200000';
    let _hash = getTopicHash(maya.address, BigNumber('0'), data, '0x00', false);
    let tx = await multiWallet.suggest(_hash);
    Events = tx.logs.find(e => e.event === 'Suggestion');
    assert.notEqual(Events, undefined);

    // 验证资产余额
    let id = tx.logs[0].args.id.toNumber();
    assert.equal(id, 1);
    let balance = await maya.balanceOf(multiWallet.address);
    assert.equal(balance, 200000000000000000000);

    /**
     * 多签钱包有200个MAYA通证了，通过多签转回去一部分
     */
    let to = maya.address;
    let value = BigNumber('0');

    // 公开交易细节
    tx = await multiWallet.reveal(id, to, value, data);
    Events = tx.logs.find(e => e.event === 'Revelation');
    assert.notEqual(Events, undefined);

    // 投票，只要三票就行
    tx = await multiWallet.approve(id, { from: owner1 });
    Events = tx.logs.find(e => e.event === 'Approval');
    assert.notEqual(Events, undefined);
    tx = await multiWallet.approve(id, { from: owner2 });
    tx = await multiWallet.approve(id, { from: owner3 });
    // let a1 = await multiWallet.isApprovedBy(id, owner1);
    let approved = await multiWallet.isApproved(id);
    assert.equal(approved, true);
    // 吊销一次，投反对票
    tx = await multiWallet.revokeApproval(id, { from: owner1 });
    Events = tx.logs.find(e => e.event === 'ApprovalRevocation');
    assert.notEqual(Events, undefined);
    approved = await multiWallet.isApproved(id);
    assert.equal(approved, false);

    tx = await multiWallet.approve(id, { from: owner4 });

    // 执行决议,可以是任何人，只能执行一次
    tx = await multiWallet.execute(id, to, value, data, '0x00', { from: accounts[5] });
    Events = tx.logs.find(e => e.event === 'Execution');
    assert.notEqual(Events, undefined);

    balance = await maya.balanceOf(multiWallet.address);
    assert.equal(balance, 0);

    // 不能执行第二次
    await assertRevert(multiWallet.execute(id, to, value, data, '0x00', { from: owner1 }));

    /**
     * 执行原生币转移，而非合约
     */
    to = owner2;
    value = BigNumber(web3.utils.toWei('2'));
    data = '0x0';
    _hash = getTopicHash(to, value, data, '0x00', true);
    // console.log('hash:', _hash);

    // 钱包众筹转移资产
    let originBalance = await web3.eth.getBalance(multiWallet.address);
    // console.log('origin balance:', originBalance);
    assert.equal(originBalance, 0);

    await web3.eth.sendTransaction({ to: multiWallet.address, from: owner1, value: web3.utils.toWei('1') });
    await web3.eth.sendTransaction({ to: multiWallet.address, from: owner2, value: web3.utils.toWei('1') });
    await web3.eth.sendTransaction({ to: multiWallet.address, from: owner3, value: web3.utils.toWei('1') });
    await web3.eth.sendTransaction({ to: multiWallet.address, from: owner4, value: web3.utils.toWei('1') });
    await web3.eth.sendTransaction({ to: multiWallet.address, from: owner5, value: web3.utils.toWei('1') });
    originBalance = await web3.eth.getBalance(multiWallet.address);
    // console.log('origin balance:', originBalance);
    assert.equal(originBalance, 5000000000000000000);

    tx = await multiWallet.suggest(_hash);
    id = tx.logs[0].args.id.toNumber();
    assert.equal(id, 2);

    tx = await multiWallet.reveal(id, to, value, data);

    tx = await multiWallet.approve(id, { from: owner1 });
    tx = await multiWallet.approve(id, { from: owner2 });
    tx = await multiWallet.approve(id, { from: owner3 });

    tx = await multiWallet.execute(id, to, value, data, '0x00', { from: accounts[5] });

    originBalance = await web3.eth.getBalance(multiWallet.address);
    // console.log('origin balance:', originBalance);
    assert.equal(originBalance, 3000000000000000000);
  });
});
