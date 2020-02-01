# Standard API for multisig wallet smart contracts

[Origin issue | 原文](https://github.com/ethereum/EIPs/issues/763)

This ERC proposes standard API for multisig wallets Ethereum smart contracts.

## 1. Motivation

Multisig wallets are widely-used class of Ethereum smart contracts. Multisig wallet is a smart contract that allows a group of people to collectively own Ethereum address and to execute transactions from it. This addresses know problem of plain Ethereum addresses controlled by private keys, where private key becomes single point of failure.
Currently, there is no common API nor implementation for multisig wallets. Being an owner of multiple multisig wallets with different APIs is a hard job, because one needs to use different tools/calls for the same operations on different wallet. This is inconvenient and error-prone. Standard API will make it possible to create convenient and secure tools one could make to deal with all his multisig wallets in the same way.

多签钱包是广泛使用的一种以太坊智能合约。多签钱包是一个允许一组人集体拥有一个以太坊地址并从中执行交易的智能合约。单纯的以太坊地址问题是被一个私钥控制的，这个所谓的私钥将会成为问题的焦点。目前没有一个通用的API，也没有一个多签的钱包实现，作为一个多个多签钱包的用户，真的好难，因为尽管实质的操作内容其实是一回事，还是需要自己去折腾不同的工具去操作不同的钱包，这个破事不方便还容易出错。标准的API将使得人们创建方便、安全的工具成为可能，人们可以用相同的方式处理自己的一堆多签钱包。

## 2. Use Cases

Proposed API supports two main use cases named “Public Flow” and “Private Flow”. Both use cases have the same roles: _Suggester_, _Approvers_, _Executor_, and the same goal: execute transaction via multisig wallet.

提议的API支持两个主要的用例，称为"公共流"和"私有流"。他们有相同的角色: _Suggester_, _Approvers_, _Executor_, 以及相同的目标: 通过多签钱包执行交易。

### 2.1. Public Flow

    1. _Suggester_ suggest transaction to be executed

    2. _Suggester_ reveals transaction details on chain, so everybody may see it

    3. _Approvers_ approve transaction

    4. _Executor_ executer transaction from multisig address

### 2.2. Private Flow

    1. _Suggester_ suggest transaction to be executed

    2. _Suggester_ sends transaction details to _Approvers_ and _Executor_ via private channels

    3. _Approvers_ approve transaction

    4. _Executor_ executer transaction from multisig address

## 3. Methods

We propose the following methods to be included into API standard: | 我们建议将以下方法纳入API标准：

### 3.1. suggest(bytes32)

##### Signature:

```javascript
function suggest (bytes32 _hash) returns (uint256 id)
```

##### Description:

Suggest transaction with given hash to be executed.

Returns unique ID of suggested transactions.

Logs “Suggestion” event.

Reverts if transaction was not suggested, e.g. when _hash is zero or caller is not authorized to suggest transactions.

Hash is calculated via the following Solidity statement:

建议执行具有给定哈希值的事务。

返回建议事务的唯一ID。

记录“建议”事件。

如果未建议事务，则还原，例如，当哈希值为零或调用方无权建议事务时。

哈希通过以下Solidity语句计算：
```
keccak256 (to, value, data, salt)
```

Here:

    * to – transaction destination address (address)

    * value – transaction value in Wei (uint256)

    * data – transaction data (bytes)

    * salt – zero for public flow, arbitrary number for private flow (uint256)

Hash may not be zero. Hash不能是0。

ID of suggested transactions are never reused. 建议的交易ID不会重复。

### 3.2. approve(uint256)
##### Signature:

```
function approve (uint256 _id)
```

##### Description:

Approve pending suggested transaction with given ID.

Logs “Approval” event.

Reverts if transaction was not approved, e.g. when _id is not a valid ID of pending suggested transaction, caller is not authorized to approve transaction or caller has already approved this transaction.

批准具有给定ID的挂起建议事务。

记录“批准”事件。

如果交易未被批准，则还原，例如，当_id不是挂起的建议交易的有效id、调用者无权批准交易或调用者已批准此交易

### 3.3. revokeApproval(uint256 _id)
##### Signature:

```
function revokeApproval (uint256 _id)
```

##### Description:

Revoke approval from suggested transaction with given ID.

Logs “ApprovalRevocation” event.

Reverts if approval was not revoked from transaction, e.g. when _id is not a valid ID of pending suggested transaction, caller is not authorized to revoke approvals or called has not approved this transaction yet.

从具有给定ID的建议交易中撤消批准。

记录“ApprovalRevocation”事件。

如果未从交易中撤销批准，则还原，例如，当_id不是挂起的建议交易的有效id、调用者无权撤销批准或调用者尚未批准此交易时。

### 3.4. execute(uint256,address,uint256,bytes,uint256)
##### Signature:

```
function execute (uint256 _id, address _to, uint256 _value, bytes _data, uint256 _salt)
returns (bool success)
```

##### Description:

Execute suggested transaction with given ID and details.

Returns true if transaction was executed successfully, false if execution failed.

Logs “Execution” event.

Reverts if transaction was not executed, e.g. when _id is not a valid ID of pending suggested transaction, transaction didn't collect enough approvals yet, transaction details do not match hash passed to “suggest” method or caller is not authorized to execute transactions.

使用给定的ID和详细信息执行建议的交易。

如果交易执行成功，则返回true；如果执行失败，则返回false。

记录“执行”事件。

如果未执行交易，则还原，例如，当id不是挂起的建议交易的有效id、交易尚未收集足够的批准、交易详细信息与传递给“建议”方法的哈希不匹配或调用方无权执行事务。

### 3.5. reveal(uint256, address, uint256, bytes)
##### Signature:

```
function reveal(uint256 _id, address _to, uint256 _value, bytes _data)
```

##### Description:

Reveal details of suggested transaction with given ID by logging “Revelation” event.

Logs “Revelation” event.

Reverts if transaction details were not revealed, e.g. when _id is not a valid ID of pending suggested transaction, transaction details (assuming zero salt) do not match hash passed to “suggest” method or caller it not authorized to reveal transaction details.

Note, that details of transactions whose hash was calculated with non-zero salt cannot be revealed.

通过记录“启示”事件，显示具有给定ID的建议交易的详细信息。

记录“启示”事件。

如果未显示交易详细信息，则还原，例如，当_id不是挂起的建议交易的有效id时，交易详细信息（假设为零盐）与传递给“建议”方法的哈希值不匹配，或与未授权其显示交易详细信息的调用方不匹配。

注意，无法显示其哈希是使用非零salt计算的交易的详细信息。

### 3.6. getHash(uint256)
##### Signature:

```
function getHash (uint256 _id) constant returns (bytes32 hash)
```

##### Description:

Get hash of details of suggested transaction with given ID.
Reverts if _id is not a valid ID of pending suggested transaction.

### 3.7. isApproved(uint256)
##### Signature:

```
function isApproved (uint256 _id) constant returns (bool approved)
```

##### Description:

Tells whether suggested transaction with given ID has collected enough approvals to be executed.
Reverts if _id is not a valid ID of pending suggested transaction.
### 3.8. isApprovedBy(uint256,address)
##### Signature

```
function isApprovedBy (uint256 _id, address _owner) constant returns (bool approved)
```

##### Description

Tells whether suggested transaction with given ID has been approved by given owner.
Reverts if _id is not a valid ID of pending suggested transaction.
## 4. Events

We propose the following events to be included into API standard:
### 4.1. Suggestion(uint256,address,bytes32)
##### Signature:

```
event Suggestion (uint256 indexed id, address indexed owner, bytes32 hash)
```

##### Description

Logged when transaction with given ID and hash of details was suggested by given owner.
### 4.2. Approval(uint256,address)
##### Signature:

```
event Approval (uint256 indexed id, address indexed owner)
```

##### Description:

Logged when transaction with given ID was approved by given owner.
### 4.3. ApprovalRevocation(uint256,address)
##### Signature:

```
event ApprovalRevocation (uint256 indexed id, address indexed owner)
```

##### Description:

Logged when approval was revoked by given owner from transaction with given ID.
### 4.4. Execution(uint256,address,bool)
##### Signature:

```
event Execution (uint256 indexed id, address indexed owner, bool result)
```

##### Description:

Logged when transaction with given ID was executed by given owner and produced given result.
### 4.5. Revelation(uint256,address,address,uint256,bytes)
##### Signature:

```
event Revelation (
  uint256 indexed id,
  address indexed owner,
  address indexed to, uint256 value, bytes data)
```

##### Description:

Logged when given details (assuming zero salt) of transaction with given ID was revealed by given owner.

