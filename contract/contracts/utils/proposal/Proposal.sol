pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

/**
 * @dev 提案投票相关基础数据结构定义.
 */
library Proposal {
  /**
    私有提案结构
    提案细节内容在链外交换
   */
  struct Rule {
    // 投票人数
    uint256 voters;
    // 生效票数
    uint256 required;
  }

  /**
    私有提案结构
    提案细节内容在链外交换
   */
  struct PrivateTopic {
    // 提案编号:唯一性ID，可以用时间戳
    uint256 id;
    // 存储索引下标
    uint256 idx;
    // 提案人
    address sponsor;
    // 提案的hash
    bytes32 hash;
    // 是否已执行
    bool executed;
  }

  /**
    公开提案结构
    提案细节内容在链外交换
   */
  struct PublicTopic {
    PrivateTopic core;
    // 目的地址
    address to;
    // 数量
    uint256 value;
    // 调用参数
    bytes data;
  }

  /**
  提案管理信息数据结构
   */
  struct ExtendInfo
  {
    PublicTopic topic;
    // 时间戳:可排序依据
    uint timestamp;
    // 结束时间
    uint endtime;
    // 提案类型
    uint voteType;
    // 提案发起前标的
    uint origin;
    // 提案发起后标的
    uint value;
    // 赞成票数
    uint yesCount;
    // 反对票数
    uint noCount;
    // 当时有效投票人数
    uint voters;
    // 当时有效百分比
    uint percent;
    // 提案标的地址
    address target;
    // 发起提案用户
    address sponsor;
  }

  /**
  投票明细的数据结构
   */
  struct VoteDetail
  {
    // 提案ID
    uint256 id;
    // 时间戳：可排序依据
    uint256 timestamp;
    // 索引下标
    uint256 idx;
    // 投票人：一个提案只能一个人只能投一个结果
    address voter;
    // 是否同意：true同意，false不同意
    bool favor;
  }
}