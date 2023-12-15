import React, { useEffect } from 'react';
import contracts from "../config/contracts.json";
import { N } from 'ethers';
interface AuctionTableProps {
  auctions: any[];

}
const AuctionTable: React.FC<AuctionTableProps> = ({ auctions = [], ...props }) => {
  
  const REVEALBID="Reveal Bid";
  const COMMITBID="Commit Bid";
  const NOTSTARTED="Not Started";
  const AUCTIONENDED="Auction Ended";

  useEffect(()=>{
    console.log("auction are",auctions);
  },[auctions])
  const handleOnActionClick=(auction:any,action:string)=>{

  }

  
  return (
    <>
      <table className="table table-bordered table-responsive">
        <thead>
          <tr>
            <th className='text-center' scope="col">Auction ID</th>
            <th className='text-center' scope="col">Token id</th>
            <th className='text-center' scope="col">Token Contract</th>
            <th className='text-center' scope="col">Start Time</th>
            <th className='text-center' scope="col">End Time</th>
            <th className='text-center' scope="col">Seller</th>
            <th className='text-center' scope="col">Auction Status</th>
            <th className='text-center' scope="col">reservePrice</th>
            <th className='text-center' scope="col">Action</th>


          </tr>
        </thead>
        <tbody>
          { auctions && auctions.map((auction: any, index: number) => {
            // Render each auction item here
            let tokenContractName={name:"",symbol:""};
            if(auction.tokenId !== null &&!Number.isNaN(auction.tokenContract)){
              //this is a EC721 token
              tokenContractName=contracts.erc721.reduce(
                (accumulator, currentValue) => currentValue.address === auction.tokenContract ? currentValue : accumulator,
                {name:"",symbol:""},
              );
            }
            const finalTokenName=`${tokenContractName.name} (${tokenContractName.symbol})`;
            const auctionStatus= auction?.contractInfo?.status ?"Open":"Closed";
            /**
             * show 
             * start time > current time -> not started 
             * 
             * current time > start time && current time < end of bidding period-> show bid button
             * current time > end of bidding period && current time < end of reveal period -> reveal bid button
             * 
             */
            const currentTime=new Date().getTime()/1000;
            let actionButtonText:string="";
            if(currentTime<auction.contractInfo.startTime){
              // auction not started yet
              actionButtonText=NOTSTARTED;
            }else if(currentTime>auction.contractInfo.startTime && currentTime<auction.contractInfo.endOfBiddingPeriod){

              // show the commit bid button
              actionButtonText=COMMITBID;
            }else if(currentTime>auction.contractInfo.endOfBiddingPeriod && currentTime<auction.contractInfo.endOfRevealPeriod){
              //show the reveal bid button
              actionButtonText=REVEALBID;
            }else{
              // auction ended
              actionButtonText=AUCTIONENDED;
            }
            return (
              <tr key={index}>
                <td className='text-center'>{auction.auctionIndex}</td>
                <td className='text-center'>{auction.tokenId}</td>
                <td className='text-center'>{finalTokenName}</td>
                <td className='text-center'>{new Date(auction.startTime*1000).toString()}</td>
                <td className='text-center'>{new Date(auction.endTime*1000).toString()}</td>
                <td className='text-center'>{auction.seller}</td>
                <td className='text-center'>{auctionStatus}</td>
                <td className='text-center'>{auction.reservePrice}</td>
                <td className='text-center'>
                  <button className={`btn btn-sm ${(actionButtonText==AUCTIONENDED || actionButtonText ==NOTSTARTED)?"btn-danger":"btn-success"}`} disabled={(actionButtonText==AUCTIONENDED || actionButtonText ==NOTSTARTED)} onClick={()=>handleOnActionClick(auction,actionButtonText)}>{actionButtonText}</button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </>
  );
};
export default AuctionTable;