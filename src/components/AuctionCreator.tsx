import React,{useEffect, useState} from 'react';
import contracts from '../config/contracts.json';

const AuctionCreator = () => {

    const [showForm, setShowForm] = useState(false);
    const [tokenContract, setTokenContract] = useState('');
    const [tokenId, setTokenId] = useState('');
    const [startTime, setStartTime] = useState("");
    const [bidPeriod, setBidPeriod] = useState('');
    const [revealPeriod, setRevealPeriod] = useState(60*60*24); // `60*60*24` is 24 hours in seconds.
    const [reservePrice, setReservePrice] = useState(0);
    const [auctionsLoading, setAuctionsLoading] = useState(false);
    const [validationError,setValidationError] = useState('');
    const ERC20='erc20';
    const ERC721='erc721';

    const [tokenType, setTokenType] = useState("");

    useEffect(()=>{


        return ()=>{
            //cleanup
            setTokenContract('');
            setTokenId('');
            setStartTime("");
            setBidPeriod('');
            setRevealPeriod(60*60*24); // `60*60*24` is 24 hours in seconds.
            setReservePrice(0);
        }
    },[])
    const validateAuctionForm =()=>{
        let error="";
        if(tokenType ==null || tokenType.length ===0 ){ 
            error = error + `Token Type is required.`;
        }

        if(tokenContract ==null || tokenContract.length ===0 ){
            error = error + `Token Contract is required.`;
        }
        if(tokenType === ERC721  && (tokenId ==null || tokenId.length ===0) ){
            error = error + "Token Id is required.";
        }   
        if(startTime ==null || startTime.length <=0 ){
            error = error + "Start Time is required. ";
        }   
        if(bidPeriod ==null || bidPeriod.length ===0 ){
            error = error + "Bid Period is required. ";
        }

        if(revealPeriod ==null || revealPeriod.toString().length ===0 ){
            error = error + "Reveal Period is required. ";
        }

        if(reservePrice ==null || reservePrice.toString().length ===0 ){
            error = error + "Reserve Price is required. ";
        }
        if(error.length > 0){
            setValidationError(error)
        }else{
            setValidationError('')
        }
    }
    const onCreateBtnClicked = async ()=>{
        validateAuctionForm();
       //print all the states
         console.log('tokenContract',tokenContract);
            console.log('tokenId',tokenId);
            console.log('startTime',startTime, new Date(startTime).getTime()/1000);
            console.log('bidPeriod',bidPeriod);
            console.log('revealPeriod',revealPeriod);
            console.log('reservePrice',reservePrice);
            console.log('tokenType',tokenType);
            
    }


    const onTokenTypeChnage = (event:any)=>{
        console.log("event is ",event.target.value);

        if(event.target.value === ERC721){
            setTokenContract(contracts.erc721[0].address);
        }else{
            setTokenContract(contracts.erc20[0].address);
        }
        setTokenType(event.target.value);
    }
    return (<>

        {!showForm && <div className='btn btn-primary' onClick={()=> setShowForm(true)}> Create Auction </div>}
        
        { showForm &&
        <div className='mt-2'>
        <div className="card" >
            <div className="card-body">
            {validationError && validationError?.length >0 && <div className="alert alert-danger" role="alert">
        Please resolve the following errors: {validationError}
</div>}
               <div className="mb-3">
               <div className='form-check'><label className="form-label">Token Type</label></div>
                <div className="form-check form-check-inline">
                <input className="form-check-input" type="radio" name="tokenType" value={ERC20} id="erc20" onChange={onTokenTypeChnage}  checked={tokenType === ERC20}/>
                <label className="form-check-label" >
                    ERC20 Token
                </label>
                </div>
                <div className="form-check form-check-inline">
                <input className="form-check-input" type="radio" name="tokenType" value={ERC721} id="erc721" onChange={onTokenTypeChnage}  checked={tokenType === ERC721}/>
                <label className="form-check-label">
                    ERC721 Token
                </label>
                </div>
               </div>
                {tokenType === ERC721 && <>
                
                    <div className="mb-3">
                    <label  className="form-label">NFT Token Contract <span className='text-danger'>*</span></label>
                    <select className="form-select" aria-label="Select your ERC271 token" onChange={id=>{

                        console.log("eslecte nft",id,id.target.value);
                        setTokenContract(id.target.value);
                    }}>
                        {contracts.erc721.map(contract=> <option key={contract.address} value={contract.address}> {`${contract.name} (${contract.symbol})`}</option>)}
                                              
                    </select>

                </div>
                <div className="mb-3">
                    <label  className="form-label">NFT Token Id <span className='text-danger'>*</span></label>
                    <input required type="text" className="form-control" value={tokenId} onChange={id=>setTokenId(id.target.value) } id="tokenId" placeholder="token id"></input>
                </div>
                
                </>}

                {tokenType === ERC20 && <>
                    <div className="mb-3">
                    <label  className="form-label">ERC 20 Token Contract <span className='text-danger'>*</span></label>
                    <select className="form-select" aria-label="Select your ERC 20 token" onChange={id=>setTokenContract(id.target.value)} value={tokenContract}>
                        {contracts.erc20.map(contract=> <option key={contract.address} value={contract.address}> {`${contract.name} (${contract.symbol})`}</option>)}
                                              
                    </select>
                </div>
                </>}
            

                <div className="mb-3">
                    <label  className="form-label">Start Time <span className='text-danger'>*</span></label>
                    <input required type="datetime-local" className="form-control" id="startTime"  value={startTime} onChange={id=>setStartTime(id.target.value) }  placeholder="start time"></input>
                </div>

                <div className="mb-3">
                    <label  className="form-label">Bid Period in Seconds <span className='text-danger'>*</span></label>
                    <input required type="number" className="form-control" id="bidPeriod"  value={bidPeriod} onChange={id=>setBidPeriod(id.target.value) }  placeholder="60"></input>
                </div>
                <div className="mb-3">
                    <label  className="form-label">Reveal Period in Seconds <span className='text-danger'>*</span></label>
                    <input type="number" className="form-control" id="revealPeriod" value={revealPeriod} onChange={id=>setRevealPeriod(parseInt(id.target.value)) }  placeholder="60"></input>
                </div>

                <div className="mb-3">
                    <label  className="form-label">Reverse Price <span className='text-danger'>*</span></label>
                    <input required type="number" className="form-control" id="reversePrice"  value={reservePrice} onChange={id=>setReservePrice(parseInt(id.target.value)) }  placeholder="60"></input>
                </div>
                
                
                <div className='row'>
                    <div className='col-6'>
                    <div onClick={onCreateBtnClicked} className="btn btn-success"> Create Auction</div>
                    </div>

                    <div className='col-6'>
                        <div className='btn btn-danger' onClick={()=>setShowForm(false)}> Cancel</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

        }
    </>);
}
export default AuctionCreator;