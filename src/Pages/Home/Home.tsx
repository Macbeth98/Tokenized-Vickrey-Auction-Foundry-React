import React from 'react';
import { useAccount, useEnsName, useConnect, useBalance } from 'wagmi'
import { InjectedConnector } from 'wagmi/connectors/injected'
import AuctionInfo from '../../components/AuctionInfo';
import AuctionCreator from '../../components/AuctionCreator';

const Home = () => {

    const { isConnected } = useAccount();
    const { connect } = useConnect({
        connector: new InjectedConnector(),
    })
    return <div className='container m-2'>

        {isConnected && <>
            <AuctionCreator />
            <AuctionInfo />
        </>}
        {!isConnected && <button className='btn btn-warning' onClick={() => connect()}>Connect Wallet</button>}

    </div>
}
export default Home;