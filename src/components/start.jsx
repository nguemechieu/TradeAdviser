import { useEffect,useState } from "react";
import Brand from "./brand/Brand";

export function Start(){

const [InitialState ,setInitialState]= useState([]);


useEffect(()=>{
    fetch('/').then((req,res)=>{

        if(res.ok){
          return res.json();
        }
    }).then(jasonResponse=>setInitialState(jasonResponse.api))

},[])

console.log(InitialState)
return <div>{InitialState.length>0 && InitialState.map((e,i)=><li key={i}>{e}</li>)}</div>
}
export default Start;