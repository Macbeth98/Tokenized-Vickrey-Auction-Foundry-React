import { useAccount, useEnsName, usePublicClient, useBalance, useContractEvent, useWalletClient, useContractRead } from 'wagmi'
import AutionTable from './AuctionTable'
import abi from '../config/abi.json';
import { useEffect, useState } from 'react';
import { ethers } from 'ethers';
function AuctionInfo() {
  const { address, isConnected } = useAccount()

  const { data, isError, isLoading } = useBalance({
    address: address,
  })
  const provider = usePublicClient();
  const [events, setEvents] = useState<any[]>([]);
  const contractAddress: any = process.env.REACT_APP_CONTRACT_ADDRESS || "";


  const convertProxyToEventObject = (args: any) => {
    let eventObject: any = {};
    Object.keys(args.toObject()).forEach(key => {
      //converting big int to number
      if (typeof args[key] === 'bigint') {
        eventObject[key] = Number(args[key]);
      } else {
        eventObject[key] = args[key];
      }


    });


    return eventObject;
  }


  // const unwatch=useContractEvent({
  //   address: contractAddress,
  //   abi: abi,
  //   eventName: 'ItemAdded',
  //   listener(logs: any){
  //     console.log("log received on watch", logs);
  //     let eventArgs: any[] = [];
  //     logs.forEach((log:any)=> {
  //       console.log("transformed information is ",log.args);
  //       eventArgs.push({...log.args, quantity:Number(log.args.quantity),addedTime:Number(log.args.addedTime)});
  //     });
  //     let mergedEvents: any[]=eventArgs.concat(events);
  //     console.log("new events are",mergedEvents)
  //     setEvents(mergedEvents);
  //   }
  // });



  // fetch the past events which are already added to the contract
  useEffect(() => {
    const alcahemyProvider = new ethers.AlchemyProvider('sepolia', process.env.REACT_APP_ALCAHEMY_KEY);
    const contract = new ethers.Contract(contractAddress, abi, alcahemyProvider);
    const listenToEvents = async () => {
      const filter = contract.filters.AuctionCreated();
      const logs: any[] = await contract.queryFilter(filter);
      let eventArgs: any[] = [];
      logs.forEach(async (log) => {
        console.log("transformed information is ", convertProxyToEventObject(log.args));
        let eventObject: any = convertProxyToEventObject(log.args);
        const contractInfo: any = await provider.readContract({
          address: contractAddress,
          abi: abi,
          functionName: 'getAuction',
          args: [eventObject.tokenContract, eventObject.tokenId],
        });
        console.log("contract info is", contractInfo);
        eventArgs.push({ ...eventObject, contractInfo: { ...contractInfo, index: Number(contractInfo.index), numUnrevealedBids: Number(contractInfo.numUnrevealedBids), secondHighestBid: Number(contractInfo.secondHighestBid), highestBid: Number(contractInfo.highestBid) } });
      });

      setEvents(eventArgs);
    };
    listenToEvents();

    provider.watchContractEvent({
      address: contractAddress,
      abi: abi,
      eventName: 'AuctionCreated',
      onLogs: (logs: any) => {
        console.log("log received on watch", logs);
        let eventArgs: any[] = [];
        logs.forEach((log: any) => {
          console.log("transformed information is ", log.args);
          eventArgs.push({ ...log.args, tokenId: Number(log.args.tokenId), reservePrice: Number(log.args.reservePrice), endTime: Number(log.args.endTime), autionIndex: Number(log.args.auctionIndex), startTime: Number(log.args.startTime) });
        });
        setEvents(prevEvents => {
          let mergedEvents = eventArgs.concat(prevEvents);
          console.log("new events are", mergedEvents);
          return mergedEvents;
        });

      }
    })
    return () => {
      // disconnect the event listener
      // if(unwatch) unwatch();

    };
  }, []);



  useEffect(() => {
    console.log("evenst updated the new events are", events);
  }, [events])




  return <>
    {isConnected &&
      <div>
        <div>Your account address is {address}</div>
        {data && !isLoading && <div> {`${data.formatted}.${data.decimals} ${data.symbol}`} </div>}

        <AutionTable auctions={events} />
      </div>}
  </>
}

export default AuctionInfo;
