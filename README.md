## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

1. Relative Stability: Anchored or Pegged -> $1.00
   相对稳定性：锚定或挂钩 -> 1.00 美元
   1. Chainlink Price feed.
      系统通过 Chainlink（一种去中心化预言机）来实时获取外界真实的美元价格。这是为了让合约知道当前 1 个 ETH 到底值多少美元。
   2. Set a function to exchange ETH & BTC -> $$$
      代码中写好了数学公式，确保抵押物价值与生成的美元稳定币之间有明确的兑换逻辑。
2. Stability Mechanism (Minting): Algorithmic (Decentralized)
   稳定机制（铸造）：算法化（去中心化）
   1. People can only mint the stablecoin with enough collateral (coded)
      (用户只有在抵押品充足的情况下才能铸造稳定币)：这被写死在代码（智能合约）中。如果你的抵押品价值不够，系统根本不会允许你把稳定币印出来，从而保证了“超额抵押”。
3. Collateral: Exogenous (Crypto)
   抵押物：外生资产（加密货币）
  1. wETH
  2. wBTC

#### 书写格式

 Layout of Contract: 
 version

 imports

 interfaces, libraries, contracts
 
 errors
 
 Type declarations
 
 State variables
 
 Events
 
 Modifiers
 
 Function
 
 Layout of Functions:
 
 constructor
 
 receive function (if exists)
 
 fallback function (if exists)
 
 external
 
 public
 
 internal
 
 private
 
 view & pure functions

 
 ### 处理vscode使用插件无效问题

 1. 检查 Foundry 的私有缓存
   Foundry 下载的编译器通常藏在这个目录，请执行：

   Bash

   ls ~/.svm/0.8.20
   如果有结果（看到一个名为 solc-0.8.20 的文件）： 我们直接把它拷贝到 VS Code 插件的缓存目录，这是最快的：

   Bash

   # 创建插件需要的目录
   mkdir -p ~/.cache/hardhat-nodejs/compilers-v2/linux-amd64/

   # 拷贝并重命名（插件只认这个长名字）
   cp ~/.svm/0.8.20/solc-0.8.20 ~/.cache/hardhat-nodejs/compilers-v2/linux-amd64/solc-linux-amd64-v0.8.20+commit.a1b79de6

   # 赋予权限
   chmod +x ~/.cache/hardhat-nodejs/compilers-v2/linux-amd64/solc-linux-amd64-v0.8.2