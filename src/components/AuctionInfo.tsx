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
  const [mapBidEvents, setMapBidEvents] = useState<any>({});
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

  const getContractInfo = async (eventObject: any) => {
    const contractInfo: any = await provider.readContract({
      address: contractAddress,
      abi: abi,
      functionName: 'getAuction',
      args: [eventObject.tokenContract, eventObject.tokenId],
    });
    console.log("contract info is", contractInfo);
    if (Number(contractInfo.index) !== Number(eventObject.auctionIndex)) {
      console.log("index mismatch.... Old Auction");
      contractInfo.status = false;
      contractInfo.endOfRevealPeriod = eventObject.endTime;
    }
    return {eventObject, contractInfo};
  }


  const getBidEvents = async (logs: any[]) => {
    const mapBids: {[key: string]: number} = mapBidEvents;

    for (const log of logs) {

      const eventObj = log.args

      console.log("Bids Events Object...", eventObj);

      const key = `${eventObj.tokenContract}-${eventObj.tokenId}-${Number(eventObj.auctionIndex)}`;

      if (mapBids[key]) {
        mapBids[key] = mapBids[key] + 1;
      } else {
        mapBids[key] = 1;
      }

    }

    console.log("Bids Events Object...", mapBids);
    return mapBids;
  }


  // fetch the past events which are already added to the contract
  useEffect(() => {
    const alcahemyProvider = new ethers.AlchemyProvider('sepolia', process.env.REACT_APP_ALCAHEMY_KEY);
    const contract = new ethers.Contract(contractAddress, abi, alcahemyProvider);
    const listenToEvents = async () => {
      const filter = contract.filters.AuctionCreated();
      const logs: any[] = await contract.queryFilter(filter);

      const eventPromises = logs.map(async (log) => {
        const eventObject: any = convertProxyToEventObject(log.args);
        const {contractInfo} = await getContractInfo(eventObject);
        return ({ ...eventObject, contractInfo: { ...contractInfo, index: Number(contractInfo.index), numUnrevealedBids: Number(contractInfo.numUnrevealedBids), secondHighestBid: Number(contractInfo.secondHighestBid), highestBid: Number(contractInfo.highestBid) } });
      })

      const eventArgs = await Promise.all(eventPromises);

      eventArgs.sort((a: any, b: any) => b.startTime - a.startTime);

      setEvents(eventArgs);
    };

    listenToEvents();

    provider.watchContractEvent({
      address: contractAddress,
      abi: abi,
      eventName: 'AuctionCreated',
      onLogs: async (logs: any) => {
        console.log("log received on watch", logs);

        const eventPromises = logs.map(async (log: any) => {
          console.log("transformed information is ", log.args);
          const {eventObject, contractInfo} = await getContractInfo(log.args);

          return ({ ...eventObject, tokenId: Number(eventObject.tokenId), auctionIndex: Number(eventObject.auctionIndex), reservePrice: Number(eventObject.reservePrice), startTime: Number(eventObject.startTime), endTime: Number(eventObject.endTime), 
             contractInfo: { ...contractInfo, index: Number(contractInfo.index), numUnrevealedBids: Number(contractInfo.numUnrevealedBids), secondHighestBid: Number(contractInfo.secondHighestBid), highestBid: Number(contractInfo.highestBid) } });
        });

        const eventArgs = await Promise.all(eventPromises);

        eventArgs.sort((a: any, b: any) => b.startTime - a.startTime);

        setEvents(prevEvents => {
          let mergedEvents = eventArgs.concat(prevEvents);
          console.log("new events are", mergedEvents);
          return mergedEvents;
        });

      }
    })


    const listenToBidEvents = async () => {
      const filter = contract.filters.BidCommitted();

      const logs: any[] = await contract.queryFilter(filter);

      const mapBidEvents = await getBidEvents(logs);

      setMapBidEvents(mapBidEvents);
    }

    listenToBidEvents();

    provider.watchContractEvent({
      address: contractAddress,
      abi: abi,
      eventName: 'BidCommitted',
      onLogs: async (logs: any) => {
        console.log("Bid Events log received on watch", logs);
        
        const mapBids = await getBidEvents(logs);

        

        setMapBidEvents((prevMapBidEvents: any[]) => {
          let mergedMapBidEvents = {...prevMapBidEvents, ...mapBids};
          console.log("new Bid Events are", mergedMapBidEvents);
          return mergedMapBidEvents;
        });
      }
    });

    return () => {
      // disconnect the event listener
      // if(unwatch) unwatch();

    };
  }, []);



  useEffect(() => {
    console.log("evenst updated the new events are", events);
  }, [events, mapBidEvents])




  return <>
    {isConnected &&
      <div>
        <div>Your account address is {address}</div>
        {data && !isLoading && <div> {`${data.formatted}.${data.decimals} ${data.symbol}`} </div>}

        <AutionTable auctions={events} mapBidEvents={mapBidEvents} />
      </div>}
  </>
}

export default AuctionInfo;
