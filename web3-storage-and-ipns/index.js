const { ethers } = require('ethers');
const provider = new ethers.providers.JsonRpcProvider(
  'https://eth-sepolia.g.alchemy.com/v2/HbChsyQOCw8Vk9-gouk858cmTSBISIqF'
);

const contractABI = require('./abi.json'); // Contract ABI array
const contractAddress = '0xbAd56510B7bf816a88A4F09417c438299efb1535'; // Address of the contract
const contract = new ethers.Contract(contractAddress, contractABI, provider);

// Assuming there's an event named 'MyEvent' in your contract
const eventName = contract.filters.ItemAdded();
const fromBlock = 0; // or a specific block number
const toBlock = 'latest'; // or a specific block number

contract
  .queryFilter(eventName, fromBlock, toBlock)
  .then((events) => {
    // Process the events array
    events.forEach((event) => {
      console.log(event);
    });
  })
  .catch((error) => {
    console.error(error);
  });
