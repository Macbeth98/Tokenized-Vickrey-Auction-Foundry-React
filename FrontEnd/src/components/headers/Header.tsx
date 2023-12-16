import React from 'react';

const Header = ()=>{

    return (
        <nav className="navbar navbar-expand-lg navbar-dark bg-primary">
  <div className="container-fluid">
    <a className="navbar-brand" href="#">Auction Board</a>
    <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
      <span className="navbar-toggler-icon"></span>
    </button>
   
  </div>
</nav>
    )
}
/**
 * contract name,
 * contract address,
 * contract symbol,
 */
export default Header;