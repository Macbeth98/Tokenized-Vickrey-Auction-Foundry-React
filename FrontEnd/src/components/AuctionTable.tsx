import React, { useState, useEffect } from 'react';
import {ethers} from 'ethers';
import { erc20ABI, useAccount, usePublicClient } from 'wagmi';
import { readContract, prepareWriteContract, writeContract, waitForTransaction } from 'wagmi/actions';
import contracts from "../config/contracts.json";
import CommitBidModal from './modals/CommitBidModal';
import { Hash } from '@wagmi/core';
import abi from '../config/abi.json';
import EndAuctionModal from './modals/EndAuctionModal';
import RevealBidModal from './modals/RevealBidModal';



interface AuctionTableProps {
  auctions: any[];
  mapBidEvents: {[key: string]: number};
}

export interface ILoaders {
  isSetFormLoading: React.Dispatch<React.SetStateAction<boolean>>;
  setLoadingMessage: React.Dispatch<React.SetStateAction<string>>;
  setHideSpinner: React.Dispatch<React.SetStateAction<boolean>>;
  setTxUrl: React.Dispatch<React.SetStateAction<string>>;
}

export interface CommitBidParams extends ILoaders {
  bidValue: number;
  nonce: string;
  balance: number;
  isFormLoading: boolean;
  loadingMessage: string;
  hideSpinner: boolean;
}

export interface RevealBidParams extends ILoaders {
  bidValue: number;
  nonce: string; 
}

const AuctionTable: React.FC<AuctionTableProps> = ({ auctions = [], mapBidEvents = {}, ...props }) => {
  
  const REVEALBID="Reveal Bid";
  const COMMITBID="Commit Bid";
  const NOTSTARTED="Not Started";
  const AUCTIONENDED="Auction Ended";
  const ENDAUCTION = "End Auction";

  const etherscanTxUrl = "https://sepolia.etherscan.io/tx/"

  const provider = usePublicClient();
  const { address } = useAccount();
  const [auction, setAuction] = useState<any>(null);
  const contractAddress: Hash = process.env.REACT_APP_CONTRACT_ADDRESS as Hash;
  
  const [isCommitModalOpen, setIsCommitModalOpen] = useState(false);
  const [isRevealModalOpen, setIsRevealModalOpen] = useState(false);
  const [isEndAuctionModalOpen, setIsEndAuctionModalOpen] = useState(false);

  useEffect(()=>{
    console.log("auction are",auctions);
  },[auctions])

  const openCommitModal = (auction: any) => {
    setAuction(auction);
    setIsCommitModalOpen(true);
  };
  
  const closeCommitModal = () => {
    setIsCommitModalOpen(false);
    setAuction(null);
  };

  const openRevealModal = (auction: any) => {
    setAuction(auction);
    setIsRevealModalOpen(true);
  }

  const closeRevealModal = () => {
    setIsRevealModalOpen(false);
    setAuction(null);
  }

  const openEndAuctionModal = (auction: any, finalTokenName: string) => {
    auction.tokenContractName = finalTokenName;
    setAuction(auction);
    setIsEndAuctionModalOpen(true);
  };

  const closeEndAuctionModal = () => {
    setIsEndAuctionModalOpen(false);
    setAuction(null);
  };

  const handleOnActionClick=(auction:any,action:string, finalTokenName: string)=>{
    switch(action){
      case REVEALBID:
        console.log("reveal bid");
        openRevealModal(auction);
        break;
      case COMMITBID:
        console.log("commit bid");
        openCommitModal(auction);
        break;
      case ENDAUCTION:
        console.log("end auction");
        openEndAuctionModal(auction, finalTokenName);
        break;
      default:
        console.log("default");
        break;
    }
  }

  const checkERC20Approved = async (erc20TokenAddress: Hash, address: Hash, spender: Hash, value: number) => {
    const allowance = await readContract({
      address: erc20TokenAddress,
      abi: erc20ABI,
      functionName: 'allowance',
      args: [address, spender],
    });

    console.log("allowance is", allowance);

    return Number(allowance) >= value;
  }

  const commitBid = async (auction: any, params: CommitBidParams) => {

    const { isSetFormLoading, setLoadingMessage, setHideSpinner, setTxUrl } = params;

    setLoadingMessage("Please wait...");
    isSetFormLoading(true);
    setHideSpinner(false);
    setTxUrl('');

    try {

      const {contractInfo} = auction;

      console.log("auction is",auction);
      console.log("params are",params);

      const nonce = ethers.encodeBytes32String(params.nonce) // input from user.
      const bidValue = params.bidValue;
      const tokenContract = auction.tokenContract;
      const tokenId = auction.tokenId;
      const auctionIndex = contractInfo.index;

      if (bidValue > params.balance) {
        alert("bid value is greater than balance");
        return;
      }

      const abiCoder = ethers.AbiCoder.defaultAbiCoder();

      const packedData = abiCoder.encode(
        ["bytes32", "uint96", "address", "uint256", "uint64"],
        [nonce, bidValue, tokenContract, tokenId, auctionIndex]
      );

      const packedHash = ethers.keccak256(packedData);
      
      const commitmentHash = packedHash.substring(0, 42);   // '0x' + 40 characters

      console.log("hash is", commitmentHash);

      if (address === undefined) {
        alert("Please connect your wallet");
        return;
      }

      const approved = await checkERC20Approved(
        contractInfo.erc20Token,
        address,
        contractAddress,
        bidValue
      );


      if (!approved) {

        alert("Please approve the contract to spend your tokens. The Next Transaction will be the approval transaction");

        setLoadingMessage("Approving ERC20 Token");
        isSetFormLoading(true);

        const approveTx = await prepareWriteContract({
          address: contractInfo.erc20Token,
          abi: erc20ABI,
          functionName: 'approve',
          args: [contractAddress, ethers.MaxInt256],
        });

        console.log("approve tx is",approveTx);

        const {hash} = await writeContract(approveTx.request);
        console.log("Approve txn hash is",hash);
        setTxUrl(etherscanTxUrl + hash);

        setLoadingMessage("Waiting for approval transaction to be mined....");
        const receipt = await waitForTransaction({chainId: provider.chain.id, hash});

        console.log("receipt is",receipt);

        if (receipt.status === "reverted") {
          setLoadingMessage("Approval transaction failed");
          setHideSpinner(true);
          return;
        }

        setLoadingMessage("ERC20 Token Approved");

        alert("ERC20 Token Approved. Now committing your bid");

      }

      setTxUrl('');

      setLoadingMessage("Committing your bid");

      const args = [
        auction.tokenContract,
        auction.tokenId,
        commitmentHash,
        bidValue
      ]

      const commitTx = await prepareWriteContract({
        address: contractAddress,
        abi: abi,
        functionName: 'commitBid',
        args,
      });

      console.log("commit tx is", commitTx);

      const { hash } = await writeContract(commitTx.request);

      console.log("commit txn hash is", hash);

      setTxUrl(etherscanTxUrl + hash);

      setLoadingMessage("Waiting for commit transaction to be mined....");

      const receipt = await waitForTransaction({ chainId: provider.chain.id, hash });

      console.log("receipt is", receipt);

      if (receipt.status === "reverted") {
        setLoadingMessage("Commit transaction failed");
        setHideSpinner(true);
        return;
      }

      alert("Bid Committed");
      setLoadingMessage("Bid Committed");
      setHideSpinner(true);

      closeCommitModal();

    } catch (e:any) {
      console.log("error is", e);
      setLoadingMessage("Error Occured...");
      setHideSpinner(true);
      alert(e.message);
    }
  }

  const revealBid = async (auction: any, params: RevealBidParams) => {
    console.log("reveal bid");

    const { isSetFormLoading, setLoadingMessage, setHideSpinner, setTxUrl  } = params;

    isSetFormLoading(true);
    setLoadingMessage("Please wait...");
    setHideSpinner(false);
    setTxUrl('');

    try {

      setLoadingMessage("Revealing your bid");

      console.log("auction is",auction);

      const nonce = ethers.encodeBytes32String(params.nonce)

      const revealTx = await prepareWriteContract({
        address: contractAddress,
        abi: abi,
        functionName: 'revealBid',
        args: [auction.tokenContract, auction.tokenId, params.bidValue, nonce],
      });

      console.log("reveal tx is", revealTx);

      const { hash } = await writeContract(revealTx.request);

      console.log("reveal txn hash is", hash);

      const txUrl = etherscanTxUrl + hash;

      setTxUrl(txUrl);

      setLoadingMessage("Waiting for reveal transaction to be mined....");

      const receipt = await waitForTransaction({ chainId: provider.chain.id, hash });

      console.log("receipt is", receipt);

      if (receipt.status === "reverted") {
        setLoadingMessage("Reveal transaction failed");
        setHideSpinner(true);
        return;
      }

      alert("Bid Revealed");
      setLoadingMessage("Bid Revealed");
      setHideSpinner(true);

      closeRevealModal();

    } catch (error: any) {
      console.log("error is", error);
      setLoadingMessage("Error Occured...");
      setHideSpinner(true);
      alert(error.message);
    }
  }

  const endAuction = async (auction: any, params: ILoaders) => {
    console.log("end auction");
    const { setHideSpinner, setLoadingMessage, isSetFormLoading, setTxUrl } = params;
    isSetFormLoading(true);
    setLoadingMessage("Please wait...");
    setHideSpinner(false);
    setTxUrl('');

    try {

      const { contractInfo } = auction;

      if (address === undefined) {
        alert("Please connect your wallet");
        return;
      }

      if (contractInfo.seller.toLowerCase() !== address.toString().toLowerCase()) {
        alert("Only the seller can end the auction");
        setHideSpinner(true);
        setLoadingMessage("Only the seller can end the auction");
        closeEndAuctionModal();
        return;
      }

      const args = [
        auction.tokenContract,
        auction.tokenId,
      ]


      setLoadingMessage("Ending Auction");

      const endAuctionTx = await prepareWriteContract({
        address: contractAddress,
        abi: abi,
        functionName: 'endAuction',
        args,
      });

      console.log("end auction tx is", endAuctionTx);

      const { hash } = await writeContract(endAuctionTx.request);

      console.log("end auction txn hash is", hash);

      const txUrl = etherscanTxUrl + hash;

      setTxUrl(txUrl);

      setLoadingMessage("Waiting for end auction transaction to be mined....");

      const receipt = await waitForTransaction({ chainId: provider.chain.id, hash });

      console.log("receipt is", receipt);

      if (receipt.status === "reverted") {
        setLoadingMessage("End auction transaction failed");
        setHideSpinner(true);
        return;
      }

      alert("Auction Ended");
      setLoadingMessage("Auction Ended");
      setHideSpinner(true);

      auction.contractInfo.status = false;

      closeEndAuctionModal();

    } catch (e:any) {
      console.log("error is", e);
      setLoadingMessage("Error Occured...");
      setHideSpinner(true);
      alert(e.message);
    }
  }

  const formatEthereumAddress = (address: string) => {
    const prefix = address.slice(0, 6);
    const suffix = address.slice(-4);
    return `${prefix}........${suffix}`;
  };

  const getBidsSubmitted = (auction: any) => {
    const key = `${auction.tokenContract}-${auction.tokenId}-${auction.auctionIndex}`;
    return mapBidEvents[key]? mapBidEvents[key]: 0;
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
            <th className='text-center' scope="col">Bids Submitted</th>
            <th className='text-center' scope="col">Auction Status</th>
            {/* <th className='text-center' scope="col">reservePrice</th> */}
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

            if (auction.contractInfo.status === false){
              actionButtonText=AUCTIONENDED;
            } else if(currentTime < auction.startTime){
              // auction not started yet
              actionButtonText=NOTSTARTED;
            }else if(currentTime>auction.startTime && currentTime<auction.contractInfo.endOfBiddingPeriod){

              // show the commit bid button
              actionButtonText=COMMITBID;
            }else if(currentTime>auction.contractInfo.endOfBiddingPeriod && currentTime<auction.contractInfo.endOfRevealPeriod){
              //show the reveal bid button
              actionButtonText=REVEALBID;
            }else{
              // auction needs to be ended
              actionButtonText = ENDAUCTION;
            }
            return (
              <tr key={index}>
                <td className='text-center'>{auction.auctionIndex}</td>
                <td className='text-center'>{auction.tokenId}</td>
                <td className='text-center'>{finalTokenName}</td>
                <td className='text-center'>{new Date(auction.startTime*1000).toString()}</td>
                <td className='text-center'>{new Date(auction.contractInfo.endOfRevealPeriod * 1000).toString()}</td>
                <td className='text-center'>{formatEthereumAddress(auction.seller)}</td>
                <td className='text-center'>{getBidsSubmitted(auction)}</td>
                <td className='text-center'>{auctionStatus}</td>
                {/* <td className='text-center'>{auction.reservePrice}</td> */}
                <td className='text-center'>
                  <button className={
                    `btn btn-sm ${(actionButtonText===AUCTIONENDED || actionButtonText===NOTSTARTED)?"btn-danger": actionButtonText === ENDAUCTION? "btn-warning": "btn-success"}`
                    } 
                    disabled={
                      (actionButtonText===AUCTIONENDED || actionButtonText===NOTSTARTED)
                      } 
                    onClick={()=>handleOnActionClick(auction,actionButtonText, finalTokenName)}>{actionButtonText}</button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      {isCommitModalOpen && <CommitBidModal auction={auction} onClose={closeCommitModal} commitBid={commitBid} />}
      {isEndAuctionModalOpen && <EndAuctionModal auction={auction} onClose={closeEndAuctionModal} endAuction={endAuction} /> }
      {isRevealModalOpen && <RevealBidModal auction={auction} onClose={closeRevealModal} revealBid={revealBid} />}
    </>
  );
};
export default AuctionTable;