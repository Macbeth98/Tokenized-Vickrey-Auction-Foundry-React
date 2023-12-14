import React from 'react';


import { WagmiConfig, createConfig, configureChains, mainnet } from 'wagmi'
import { jsonRpcProvider } from 'wagmi/providers/jsonRpc'
import AuctionInfo from './components/AuctionInfo';
import Header from './components/headers/Header';
import Home from './Pages/Home/Home';

const { chains, publicClient, webSocketPublicClient } = configureChains(
  [mainnet],
  [
    jsonRpcProvider({
      rpc: (chain) => ({
        http: `${process.env.REACT_APP_HTTP_URL}/${process.env.REACT_APP_ALCAHEMY_KEY}`,
        webSocket: `${process.env.REACT_APP_WEBSOCEKT_URL}/${process.env.REACT_APP_ALCAHEMY_KEY}`,
      }),
    }),
  ],
)

const config = createConfig({
  autoConnect: true,
  publicClient,
  webSocketPublicClient,
})

function App() {
  return (
    <div className="App">
      <Header/>
          <WagmiConfig  config={config}>
          <Home/>
        </WagmiConfig>
      
    </div>
  );
}

export default App;
