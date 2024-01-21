import './App.css' 

import ConnectBtn from './ConnectBtn'
import Bank from "./NFTMarket"
const App = () => {

  return (
    <>
      <div className="app">  
        <ConnectBtn />
        
        <Bank/>
      </div>
    </>
  )
}

export default App