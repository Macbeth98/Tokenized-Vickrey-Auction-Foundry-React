import { readContract } from 'wagmi/actions';
import { erc20ABI, useAccount } from 'wagmi';
import { useState } from 'react';
import { ILoaders } from '../AuctionTable';

const EndAuctionModal =  ({ auction, onClose, endAuction }: {auction: any, onClose: () => void, endAuction: (auction: any, params: ILoaders) => void}) => {
  const defaultLoadingMessage = "Please Wait...";
  
  const [isFormLoading, isSetFormLoading] = useState<boolean>(false);
  const [loadingMessage, setLoadingMessage] = useState<string>(defaultLoadingMessage);
  const [hideSpinner, setHideSpinner] = useState<boolean>(false);
  const [txUrl, setTxUrl] = useState<string>('');



  const handleEndAuction = () => {
    endAuction(auction, { setLoadingMessage, setHideSpinner, isSetFormLoading, setTxUrl });
  }

  return (
    <div className="modal" style={{ display: 'block' }}>
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">End Auction {auction?.auctionIndex}</h5>
            <button type="button" className="close" onClick={onClose}>&times;</button>
          </div>
          <div className="modal-body">
            <h3>End Auction</h3>
            <p>Please Confirm to End Auction by clicking the Confirm button below. </p>

            <div className="mb-3">
              <label className="form-label">Auction Index: {auction.contractInfo.index}</label> <br />
              <label className="form-label">Token Contract: {auction.tokenContractName}</label> <br />
              <label className="form-label">Token ID: {auction.tokenId}</label> <p></p>
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
            <button type="button" className="btn btn-danger" onClick={handleEndAuction}>End Auction</button>
          </div>
        </div>
      </div>
    </div>
  );
};


export default EndAuctionModal;
