const Utils = require('jcc-ethereum-utils').Ethereum

module.exports = function(to, value, data, salt, memo) {
  /**
   * 模拟 abi.encodePacked()函数打包数据，有两种状况
   * 1. 调用智能合约的calldata,前8个字符（4字节）是函数签名
   * 2. 正常转账的备注，其实是一个bytes数组，数组需要有一个前导长度定义
   */
  let _data = Utils.filter0x(data)
  let signatureLen = 8
  let _salt, s

  _salt = web3.utils.padRight(Utils.filter0x(salt), 64)

  if (memo) {
    if (_data.replace(/0/g, '').length === 0) {
      _data = ''
    }

    s = to + web3.utils.padLeft(value.toString(16), 64) + ((_data.length / 2) + '').toString(16) + _data + _salt
  } else {
    // bytes要凑齐32个字节
    if ((_data.length - signatureLen) % 64) {
      let m = (_data.length - signatureLen) % 64
      _data = web3.utils.padRight(_data, m === 0 ? _data.length : _data.length + 64 - m)
    }

    s = to + web3.utils.padLeft(value.toString(16), 64) + _data + _salt
  }

  let hash = web3.utils.sha3(s.toLowerCase())

  return hash
}
