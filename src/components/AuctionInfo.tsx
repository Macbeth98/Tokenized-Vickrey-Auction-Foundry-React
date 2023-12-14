import { useAccount, useEnsName,usePublicClient,useBalance, useContractEvent, useWalletClient } from 'wagmi'
import AutionTable from './AuctionTable'
import abi from '../config/abi.json';
import { useEffect, useState } from 'react';
import {ethers} from 'ethers';
function AuctionInfo() {
    const { address, isConnected } = useAccount()
   
    const { data, isError, isLoading } = useBalance({
      address: address,
    })
    const provider= usePublicClient();
    const [events, setEvents] = useState([]);
    const contractAddress:any= process.env.REACT_APP_CONTRACT_ADDRESS || "";
    
    const {data:signer}= useWalletClient();
    useEffect(()=>{
      console.log("This is the signer and provider information",signer,provider)
      const fetchEvents = async () => {
        try {
          const eventFilter :any = {
            address: contractAddress, // Replace with your contract address
            topics: ["ItemAdded"], // Replace with the topics of your event
            fromBlock: 'earliest', // Starting block
            toBlock: 'latest', // Fetch up to the latest block
          };
  
          const logs:any = await provider.getLogs(eventFilter);
          // Process logs if needed
          setEvents(logs);
        } catch (error) {
          console.error('Error fetching events:', error);
        }
      };

      // const contract= new ethers.Contract(contractAddress,abi,provider);
      // const listenToEvents = async () => {
      //   const filter = contract.filters.ItemAdded()
      //   const logs = await contract.queryFilter(filter)
      //   logs.forEach(log => {
      //     console.log(log) // log.args contains the ItemAdded event arguments
      //   })
      // }
  
      // listenToEvents()
      provider.watchContractEvent({
        address: contractAddress,
        abi: abi,
        eventName: 'ItemAdded',
        onLogs:log=>console.log("this is the provider logs information",log),
    
      });
  
      //fetchEvents();
    },[provider])
  
   

    return <>
    {isConnected &&
    <div>
      <div>Your account address is {address}</div>
        {data && <div> {`${data.formatted}.${data.decimals} ${data.symbol}`} </div>}
        <AutionTable/>
      </div>}
    </>
}

export default AuctionInfo;
