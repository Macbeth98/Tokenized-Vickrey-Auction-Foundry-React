import React from 'react';


const AutionTable = ()=>{

    return (<>
        <table className="table table-bordered">
  <thead >
    <tr>
      <th className='text-center'  scope="col">NFT ID</th>
      <th className='text-center'  scope="col">Auction Status</th>
      <th className='text-center'  scope="col">Created On</th>
      <th className='text-center' scope="col">Bids Placed</th>
      <th className='text-center' scope="col">Closes On</th>
      <th className='text-center' scope="col">Action Bid</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th className='text-center' scope="row">1</th>
      <td className='text-center text-success' >Open</td>
      <td className='text-center' >12/12/2023</td>
      <td className='text-center' >100</td>
      <td  className='text-center' >12/12/2024</td>
      <td className='text-center' > <button className='btn btn-sm btn-success'>Bid</button></td>
    </tr>
   <tr>
    <th className='text-center' scope="row">2</th>
      <td className='text-center text-danger' >Closed</td>
      <td className='text-center' >12/12/2022</td>
      <td className='text-center' >100</td>
      <td  className='text-center' >12/12/2023</td>
      <td className='text-center' > </td>
    </tr>
  </tbody>
</table>
    </>)

}
export default AutionTable;