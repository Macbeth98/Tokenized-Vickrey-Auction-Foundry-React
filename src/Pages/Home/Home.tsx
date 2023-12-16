import React, { useState } from 'react';
import { useAccount, useEnsName, useConnect, useBalance } from 'wagmi'
import { InjectedConnector } from 'wagmi/connectors/injected'
import AuctionInfo from '../../components/AuctionInfo';
import AuctionCreator from '../../components/AuctionCreator';
import TokenBalance from '../../components/TokenBalances';

export interface ITokenSetInfo {
    tokenContract: any;
    setTokenContract: React.Dispatch<any>;
    erc20TokenContract: any;
    setErc20TokenContract: React.Dispatch<any>;
}

const Home = () => {

    const { isConnected } = useAccount();
    const { connect } = useConnect({
        connector: new InjectedConnector(),
    })

    const [tokenContract, setTokenContract] = useState<any>('');
    const [erc20TokenContract, setErc20TokenContract] = useState<any>('');

    return <div className='container m-2'>

        {isConnected && <>
            <AuctionCreator tokenContract={tokenContract} setTokenContract={setTokenContract} erc20TokenContract={erc20TokenContract} setErc20TokenContract={setErc20TokenContract} />
            <p></p>
            <TokenBalance tokenContract={tokenContract} setTokenContract={setTokenContract} erc20TokenContract={erc20TokenContract} setErc20TokenContract={setErc20TokenContract} />
            <p></p>
            <AuctionInfo />
        </>}
        {!isConnected && <button className='btn btn-warning' onClick={() => connect()}>Connect Wallet</button>}

    </div>
}
export default Home;