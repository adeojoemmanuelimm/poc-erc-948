import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import { readFileSync } from 'fs';

const TESTNET_GAS_MULT = 1.1;

const mnemonic = readFileSync('.testnet.seed-phrase').toString().trim();
if (!mnemonic || mnemonic.split(' ').length !== 12) {
  console.log('unable to retrieve mnemonic from .secret');
}

const gasPriceTestnetRaw = readFileSync('.minimum-gas-price-testnet.json').toString().trim();
const minimumGasPriceTestnet = parseInt(JSON.parse(gasPriceTestnetRaw).result.minimumGasPrice, 16);

if (typeof minimumGasPriceTestnet !== 'number' || Number.isNaN(minimumGasPriceTestnet)) {
  throw new Error('unable to retrieve network gas price from .gas-price-testnet.json');
}
console.log(`Minimum gas price Testnet: ${minimumGasPriceTestnet}`);

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const config: HardhatUserConfig = {
  solidity: '0.8.14',
  networks: {
    rsktestnet: {
      chainId: 31,
      url: 'https://public-node.testnet.rsk.co/',
      gasPrice: Math.floor(minimumGasPriceTestnet * TESTNET_GAS_MULT),
      gasMultiplier: TESTNET_GAS_MULT,
      accounts: {
        mnemonic: mnemonic,
        initialIndex: 0,
        path: "m/44'/60'/0'/0",
        count: 10,
      },
    },
  },
};

export default config;
