import React, { useEffect, useState } from 'react';
import contracts from '../config/contracts.json';
import abi from '../config/abi.json';
import erc721 from "../config/erc721.json";
import { useAccount, usePublicClient } from 'wagmi';
import { prepareWriteContract, writeContract, waitForTransaction } from 'wagmi/actions';
import { Hash } from 'viem';
import { ITokenSetInfo } from '../Pages/Home/Home';

const AuctionCreator = ({tokenContract, setTokenContract, erc20TokenContract, setErc20TokenContract}: ITokenSetInfo) => {
    const defaultLoadingMessage = "Please Wait...";

    const contractAddress: Hash = process.env.REACT_APP_CONTRACT_ADDRESS as Hash;
    const { isConnected, address } = useAccount();
    const [showForm, setShowForm] = useState(false);
    // const [tokenContract, setTokenContract] = useState<any>('');
    // const [erc20TokenContract, setErc20TokenContract] = useState<any>('');
    const [tokenId, setTokenId] = useState('');
    const [startTime, setStartTime] = useState("");
    const [bidPeriod, setBidPeriod] = useState(60 * 60);
    const [revealPeriod, setRevealPeriod] = useState(60 * 60 ); // `60*60*24` is 24 hours in seconds.
    const [reservePrice, setReservePrice] = useState(10);
    const [auctionsLoading, setAuctionsLoading] = useState(false);
    const [validationError, setValidationError] = useState('');
    const ERC20 = 'erc20';
    const ERC721 = 'erc721';
    const provider = usePublicClient();
    const [tokenType, setTokenType] = useState("");

    const [showApprovalBtn, setShowApprovalBtn] = useState(false);

    const [isFormLoading, isSetFormLoading] = useState<boolean>(false);
    const [loadingMessage, setLoadingMessage] = useState<string>(defaultLoadingMessage);
    useEffect(() => {


        return () => {
            //cleanup
            setTokenContract('');
            setErc20TokenContract('');
            setTokenId('');
            setStartTime("");
            setBidPeriod(60 * 60);
            setRevealPeriod(60 * 60); // `60*60*24` is 24 hours in seconds.
            setReservePrice(10);
        }
    }, [])

    const validateAuctionForm = () => {
        let error = "";
        if (tokenType == null || tokenType.length === 0) {
            error = error + `Token Type is required.`;
        }

        if (tokenContract == null || tokenContract.length === 0) {
            error = error + `Token Contract is required.`;
        }
        if (tokenType === ERC721 && (tokenId == null || tokenId.length === 0)) {
            error = error + "Token Id is required.";
        }
        if (startTime == null || startTime.length <= 0) {
            error = error + "Start Time is required. ";
        }
        if (bidPeriod == null || bidPeriod.toString().length === 0) {
            error = error + "Bid Period is required. ";
        }

        if (revealPeriod == null || revealPeriod.toString().length === 0) {
            error = error + "Reveal Period is required. ";
        }

        if (reservePrice == null || reservePrice.toString().length === 0) {
            error = error + "Reserve Price is required. ";
        }
        if (error.length > 0) {
            setValidationError(error)
            return false;
        } else {
            setValidationError('')
            return true;
        }
    }
    const onCreateBtnClicked = async () => {
        const valid = validateAuctionForm();

        if (!valid) {
            return;
        }

        console.log('tokenContract', tokenContract);
        console.log('tokenId', tokenId);
        console.log('erc20TokenContract', erc20TokenContract);
        console.log('startTime', startTime, new Date(startTime).getTime() / 1000);
        console.log('bidPeriod', bidPeriod);
        console.log('revealPeriod', revealPeriod);
        console.log('reservePrice', reservePrice);
        console.log('tokenType', tokenType);

        if (validationError.length <= 0) {
            //check for the approval of the token
            try {
                const ownerInfo: any = await provider.readContract({
                    address: tokenContract,
                    abi: erc721,
                    functionName: 'ownerOf',
                    args: [tokenId],
                });
                //check if the current wallet address is same as the owner of the token

                if (ownerInfo.toLowerCase() !== address?.toString().toLowerCase()) {
                    alert("You are not the owner of the token");
                    return;
                }

            } catch (error: any) {

                alert(error.message);
                return;
            }

            try {
                const approvalInfo: any = await provider.readContract({
                    address: tokenContract,
                    abi: erc721,
                    functionName: 'getApproved',
                    args: [tokenId],
                });

                console.log("approval info is ", approvalInfo);
                // check if the auction contract is approved to transfer the token
                if (approvalInfo.toLowerCase() !== contractAddress.toLowerCase()) {
                    // enable a button for user to ask him for approval
                    setShowApprovalBtn(true);
                    return
                } else {
                    createAuction();
                }
            } catch (error: any) {
                alert(error.message);
                return;
            }
        }

    }


    const createAuction = async () => {
        setLoadingMessage('Preparing to create the Auction...');
        isSetFormLoading(true);
        setValidationError('');

        try {
            const createAuctionContract = await prepareWriteContract({
                address: contractAddress,
                abi: abi,
                functionName: 'createAuction',
                args: [tokenContract, tokenId, erc20TokenContract, new Date(startTime).getTime() / 1000, bidPeriod, revealPeriod, reservePrice],
            });
    
            console.log("createAuctionContract is ", createAuctionContract);
    
            const { hash } = await writeContract(createAuctionContract.request);
            console.log("hash is ", hash);
            setLoadingMessage('Waiting for the Auction transaction to be mined...' + hash);
    
            const receipt = await waitForTransaction({ chainId: provider.chain.id, hash });
            console.log("receipt is ", receipt);
    
            if (receipt.status !== "success") {
                throw new Error("Auction creation failed");
            }

        } catch (error: any) {
            setValidationError(error.message);
        }

        isSetFormLoading(false);
        setLoadingMessage(defaultLoadingMessage);

    }

    const approveAuctionContract = async () => {
        setLoadingMessage("Approving the auction contract to transfer the token");
        isSetFormLoading(true);
        setValidationError('');
        try {
            const {request} = await prepareWriteContract({
                address: tokenContract,
                abi: erc721,
                functionName: 'approve',
                args: [process.env.REACT_APP_CONTRACT_ADDRESS, tokenId],
                account: address,
            })

            console.log("request is ",request);
            
            const {hash} = await writeContract(request);
            console.log("hash is ",hash);

            setLoadingMessage("Waiting for the transaction to be mined...");

            const receipt = await waitForTransaction({chainId: provider.chain.id, hash});
            console.log("receipt is ",receipt);

            if (receipt.status !== "success") {
                throw new Error("Approval failed");
            }
            
            setShowApprovalBtn(false);
        } catch (error: any) {
            console.log("error is ",error.message);
            setValidationError(error.message);
        }

        isSetFormLoading(false);
        setLoadingMessage(defaultLoadingMessage);
    }

    const onTokenTypeChnage = (event: any) => {
        console.log("event is ", event.target.value);

        if (event.target.value === ERC721) {
            const contract = tokenContract.length > 0 ? tokenContract : contracts.erc721[0].address;
            setTokenContract(contract);
        } else {
            const contract = erc20TokenContract.length > 0 ? erc20TokenContract : contracts.erc20[0].address;
            setErc20TokenContract(contract);
        }
        setTokenType(event.target.value);
    }
    return (<>

        {!showForm && <div className='btn btn-primary' onClick={() => setShowForm(true)}> Create Auction </div>}

        {showForm &&
            <div className='mt-2'>
                <div className="card" >
                    <div className="card-body">
                        {validationError && validationError?.length > 0 && <div className="alert alert-danger" role="alert">
                            Please resolve the following errors: {validationError}
                        </div>}
                        {showApprovalBtn  && !isFormLoading && <div className="alert alert-warning" role="alert">
                            Please  click on the approve button at the bottom to approve the auction contract to transfer the token
                        </div>}
                        {isFormLoading && <div className="d-flex align-items-center">
                            <strong>{loadingMessage}</strong>
                            <div className="spinner-border ms-auto" role="status" aria-hidden="true"></div>
                        </div>}
                        {
                            !isFormLoading && <>

                                <div className="mb-3">
                                    <div className='form-check'><label className="form-label">Token Type</label></div>
                                    <div className="form-check form-check-inline">
                                        <input className="form-check-input" type="radio" name="tokenType" value={ERC20} id="erc20" onChange={onTokenTypeChnage} checked={tokenType === ERC20} />
                                        <label className="form-check-label" >
                                            ERC20 Token
                                        </label>
                                    </div>
                                    <div className="form-check form-check-inline">
                                        <input className="form-check-input" type="radio" name="tokenType" value={ERC721} id="erc721" onChange={onTokenTypeChnage} checked={tokenType === ERC721} />
                                        <label className="form-check-label">
                                            ERC721 Token
                                        </label>
                                    </div>
                                </div>
                                {tokenType === ERC721 && <>

                                    <div className="mb-3">
                                        <label className="form-label">NFT Token Contract <span className='text-danger'>*</span></label>
                                        <select className="form-select" aria-label="Select your ERC271 token" value={tokenContract} onChange={id => {

                                            console.log("eslecte nft", id, id.target.value);
                                            setTokenContract(id.target.value);
                                        }}>
                                            {contracts.erc721.map(contract => <option key={contract.address} value={contract.address}> {`${contract.name} (${contract.symbol})`}</option>)}

                                        </select>

                                    </div>
                                    <div className="mb-3">
                                        <label className="form-label">NFT Token Id <span className='text-danger'>*</span></label>
                                        <input required type="number" className="form-control" value={tokenId} onChange={id => setTokenId(id.target.value)} id="tokenId" placeholder="token id"></input>
                                    </div>

                                </>}

                                {tokenType === ERC20 && <>
                                    <div className="mb-3">
                                        <label className="form-label">ERC 20 Token Contract <span className='text-danger'>*</span></label>
                                        <select className="form-select" aria-label="Select your ERC 20 token" onChange={id => setErc20TokenContract(id.target.value)} value={erc20TokenContract}>
                                            {contracts.erc20.map(contract => <option key={contract.address} value={contract.address}> {`${contract.name} (${contract.symbol})`}</option>)}

                                        </select>
                                    </div>
                                </>}


                                <div className="mb-3">
                                    <label className="form-label">Start Time <span className='text-danger'>*</span></label>
                                    <input required type="datetime-local" className="form-control" id="startTime" value={startTime} onChange={id => setStartTime(id.target.value)} placeholder="start time"></input>
                                </div>

                                <div className="mb-3">
                                    <label className="form-label">Bid Period in Seconds <span className='text-danger'>*</span></label>
                                    <input required type="number" className="form-control" id="bidPeriod" value={bidPeriod} onChange={id => setBidPeriod(parseInt(id.target.value))} placeholder="60"></input>
                                </div>
                                <div className="mb-3">
                                    <label className="form-label">Reveal Period in Seconds <span className='text-danger'>*</span></label>
                                    <input type="number" className="form-control" id="revealPeriod" value={revealPeriod} onChange={id => setRevealPeriod(parseInt(id.target.value))} placeholder="60"></input>
                                </div>

                                <div className="mb-3">
                                    <label className="form-label">Reverse Price <span className='text-danger'>*</span></label>
                                    <input required type="number" className="form-control" id="reversePrice" value={reservePrice} onChange={id => setReservePrice(parseInt(id.target.value))} placeholder="60"></input>
                                </div>


                                <div className='row'>
                                    <div className='col-6'>
                                        {!showApprovalBtn && <div onClick={onCreateBtnClicked} className="btn btn-success"> Create Auction</div>}
                                        {showApprovalBtn && <div onClick={approveAuctionContract} className="btn btn-warning"> Approve Auction Contract</div>}

                                    </div>

                                    <div className='col-6'>
                                        <div className='btn btn-danger' onClick={() => setShowForm(false)}> Cancel</div>
                                    </div>
                                </div>

                            </>
                        }
                    </div>
                </div>
            </div>

        }
    </>);
}
export default AuctionCreator;