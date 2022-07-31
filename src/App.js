
import './App.css';
import { logo} from './logo.svg';
import {Footer,Blog,Header,Possibility,whatGP3} from './containers'
import {Brand, Cta, Features, Navbar,Articles} from "./components";
import{Start} from './components/start';
function App() {
  return (
      <div className="App">
    <div className="gradient_bg">
      <Navbar />
        <Header/>
         </div>
         <Brand/>
        
         <Start />
           <whatGP3/>
            <Features />
             <Possibility />
             <Cta />
               <Blog />
                  <Articles/>
                   <Footer />
      </div>


  );
}

export default App;
