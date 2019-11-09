module.exports = {
  merkleTreeConfig: {
    cmdTreeName: process.env.CMD_TREE_NAME || 'CmdTree',
    treeDepth: process.env.MERKLE_TREE_DEPTH || 4,
    zeroValue: 0n,
    durationSignUpBlockNumbers: process.env.SIGNUP_BLOCK_DURATION || 20
  },
  ganacheConfig: {
    mnemonic: 'helloworld',
    host: 'http://localhost:8545',
    privateKey: '0x94a9f52a9ef7933f3865a91766cb5e12d25f62d6aecf1d768508d95526bfee29'
  }
}
