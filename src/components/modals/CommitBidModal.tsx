import { readContract } from 'wagmi/actions';
import { erc20ABI, useAccount } from 'wagmi';
import { useState } from 'react';
import { CommitBidParams } from '../AuctionTable';

const CommitBidModal =  ({ auction, onClose, commitBid }: {auction: any, onClose: () => void, commitBid: (auction: any, params: CommitBidParams) => void}) => {
  const defaultLoadingMessage = "Please Wait...";

  const { address } = useAccount();
  const [bidValue, setBidValue] = useState(0);
  const [nonce, setNonce] = useState('');
  const [erc20TokenName, setErc20TokenName] = useState('');
  const [erc20TokenSymbol, setErc20TokenSymbol] = useState('');
  const [balance, setBalance] = useState(0);
  
  const [isFormLoading, isSetFormLoading] = useState<boolean>(false);
  const [loadingMessage, setLoadingMessage] = useState<string>(defaultLoadingMessage);
  const [hideSpinner, setHideSpinner] = useState<boolean>(false);

  const [txUrl, setTxUrl] = useState<string>('');

  const fetchERC20TokenInfo = async () => {
    const erc20TokenName = await readContract({
      address: auction?.contractInfo?.erc20Token,
      abi: erc20ABI,
      functionName: 'name',
    });

    setErc20TokenName(erc20TokenName);

    const erc20TokenSymbol = await readContract({
      address: auction?.contractInfo?.erc20Token,
      abi: erc20ABI,
      functionName: 'symbol',
    })

    setErc20TokenSymbol(erc20TokenSymbol);

    console.log("address is", address);
    if (address === undefined) return;
    const balance = await readContract({
      address: auction?.contractInfo?.erc20Token,
      abi: erc20ABI,
      functionName: 'balanceOf',
      args: [address],
    });

    console.log("balance is", balance);

    setBalance(Number(balance) as unknown as number);
  }

  fetchERC20TokenInfo();

  const handleCommitBid = () => {
    commitBid(auction, { bidValue, nonce, balance, isFormLoading, isSetFormLoading, loadingMessage, setLoadingMessage, hideSpinner, setHideSpinner, setTxUrl });
  }

  return (
    <div className="modal" style={{ display: 'block' }}>
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">Commit Bid for Auction {auction?.auctionIndex}</h5>
            <button type="button" className="close" onClick={onClose}>&times;</button>
          </div>
          <div className="modal-body">
            <h3>Place Your Bid</h3>
            <p>Please enter your bid details below </p>

            <div className="mb-3">
              <label className="form-label">Your Bid Value is in the ERC20 Token</label>
              <p><strong>{erc20TokenName} ({erc20TokenSymbol})</strong></p>
              <label className="form-label">Your Balance: </label>
              <p><strong>{balance} <a target='blank' href={`https://sepolia.etherscan.io/address/${auction.contractInfo.erc20Token}#writeContract`}>(Mint More from Etherscan)</a> </strong></p>
            </div>

            <div className="mb-3">
              <label htmlFor="bidValue" className="form-label">Bid Value</label>
              <input type="number" className="form-control" id="bidValue" onChange={e => setBidValue(Number(e.target.value))} placeholder="Enter bid value"/>
            </div>

            <div className="mb-3">
              <label htmlFor="bidNonce" className="form-label">Nonce</label>
              <input type="text" className="form-control" id="bidNonce" onChange={e => setNonce(e.target.value)} placeholder="Enter nonce"/>
            </div>

            <div className='mb-3'>
              <a href={txUrl} target='blank'>{txUrl.length > 0? "View Transaction On EtherScan": ""}</a>
            </div>

            <>
          {isFormLoading && <div className="d-flex align-items-center">
                            <strong>{loadingMessage}</strong>
                            <div className="spinner-border ms-auto" role="status" hidden={hideSpinner} aria-hidden="true"></div>
                        </div>}
            </>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={onClose}>Close</button>
            <button type="button" className="btn btn-primary" onClick={handleCommitBid}>Commit Bid</button>
          </div>
        </div>
      </div>
    </div>
  );
};


export default CommitBidModal;
