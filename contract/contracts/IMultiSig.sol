pragma solidity 0.4.24;

/**
  多签名钱包接口
 */
interface IMultiSig {
  // 提案日志
  event Suggestion(uint256 indexed id, address indexed owner, bytes32 hash);

  // 批准日志
  event Approval(uint256 indexed id, address indexed owner);

  // 撤销批准日志
  event ApprovalRevocation(uint256 indexed id, address indexed owner);

  // 执行日志
  event Execution(uint256 indexed id, address indexed owner, bool result);

  // 提案日志
  event Revelation(uint256 indexed id, address indexed owner, address indexed to, uint256 value, bytes data);

  /**
    提案
    hash 由 keccak256 (to, value, data, salt)就算得出
    salt为0表示提案是公开的,不为0表示秘密提案，可以在链外交换
   */
  function suggest(bytes32 _hash) external returns (uint256 id);

  // // 对提案进行批准
  function approve(uint256 _id) external;

  // // 撤销自己的批准
  function revokeApproval(uint256 _id) external;

  /**
    执行批准的提案
    执行提案的细节内容来源有两种情况
    1. 来自公开的提案信息，有 reveal 函数提交，那么salt固定为0
    2. 来自链外的交换，那么要验证细节数据计算的hash是否一致，id是否存在，然后发起调用
    对于普通用户来说，这个接口人工阅读很费解，需要应用层进行形象化处理
   */
  function execute(uint256 _id, address _to, uint256 _value, bytes _data, uint256 _salt) public returns (bool success);

  /**
    公开提案明细信息，如果是私有流程，该函数不必调用，链外协调
    hash 由 keccak256 (to, value, data, salt)计算得出，在公开流程中salt始终未0
    TODO: 这里接口用了public 而不是 external 是因为低版本的solidity编译器的缘故，具体请参见
    https://github.com/ethereum/solidity/issues/4832 主要原因在于数组和bytes类型
    这会产生一堆的编译警告，比编译不过要强点
   */
  function reveal(uint256 _id, address _to, uint256 _value, bytes _data) public;

  // 根据id获取提案hash
  function getHash(uint256 _id) external view returns (bytes32 hash);
  // 根据id获取批准状态
  function isApproved(uint256 _id) external view returns (bool approved);
  // 根据id获取每个投票人的批准状态
  function isApprovedBy(uint256 _id, address _owner) external view returns (bool approved);
}