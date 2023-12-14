import { useAccount, useEnsName, usePublicClient, useBalance, useContractEvent, useWalletClient } from 'wagmi'
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


  const convertProxyToEventObject=(args:any)=>{
    let eventObject: any = {};
    Object.keys(args.toObject()).forEach(key => {
      //converting big int to number
      if (typeof args[key] === 'bigint') {
        eventObject[key] = Number(args[key]);
      } else {
        eventObject[key] =args[key];
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
      const filter = contract.filters.ItemAdded();
      const logs: any[] = await contract.queryFilter(filter);
      let eventArgs: any[] = [];
      logs.forEach(log => {
        console.log("transformed information is ",convertProxyToEventObject(log.args));
        eventArgs.push(convertProxyToEventObject(log.args));
      });
      setEvents(eventArgs);
    };
    listenToEvents();

    provider.watchContractEvent({
      address: contractAddress,
      abi: abi,
      eventName: 'ItemAdded',
      onLogs:(logs: any)=>{
        console.log("log received on watch", logs);
        let eventArgs: any[] = [];
        logs.forEach((log:any)=> {
          console.log("transformed information is ",log.args);
          eventArgs.push({...log.args, quantity:Number(log.args.quantity),addedTime:Number(log.args.addedTime)});
        });
        setEvents(prevEvents => {
          let mergedEvents = eventArgs.concat(prevEvents);
          console.log("new events are", mergedEvents);
          return mergedEvents;
        });
        
      }
    })
    return ()=>{
      // disconnect the event listener
      // if(unwatch) unwatch();
    };
  }, []);



  useEffect(()=>{
    console.log("evenst updated the new events are",events);
  },[events])
  



  return <>
    {isConnected &&
      <div>
        <div>Your account address is {address}</div>
        {data && !isLoading && <div> {`${data.formatted}.${data.decimals} ${data.symbol}`} </div>}
        <div>
          <ul>
            {events && events.sort((e1,e2)=>e2.addedTime-e1.addedTime).map((event, index) => <li key={index}>  name:{event.itemName},  Quantity:{event.quantity}, addedTime:{`${new Date(event.addedTime*1000)}`}</li>)}
          </ul>
        </div>

        <AutionTable />
      </div>}
  </>
}

export default AuctionInfo;
