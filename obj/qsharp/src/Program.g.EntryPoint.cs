//------------------------------------------------------------------------------
// <auto-generated>                                                             
//     This code was generated by a tool.                                       
//     Changes to this file may cause incorrect behavior and will be lost if    
//     the code is regenerated.                                                 
// </auto-generated>                                                            
//------------------------------------------------------------------------------
using System;
using Microsoft.Quantum.Core;
using Microsoft.Quantum.Intrinsic;
using Microsoft.Quantum.Simulation.Core;

namespace Walks
{
    internal class __QsEntryPoint__TestingStates : Microsoft.Quantum.EntryPointDriver.IEntryPoint
    {
        public string Name => "Walks.TestingStates";
        public string Summary => "";
        public System.Collections.Generic.IEnumerable<System.CommandLine.Option> Options => new System.CommandLine.Option[] { };
        public QVoid CreateArgument(System.CommandLine.Parsing.ParseResult parseResult) => QVoid.Instance;
        public System.Threading.Tasks.Task<int> Submit(System.CommandLine.Parsing.ParseResult parseResult, Microsoft.Quantum.EntryPointDriver.AzureSettings settings) => Microsoft.Quantum.EntryPointDriver.Azure.Submit(global::Walks.TestingStates.Info, this.CreateArgument(parseResult), settings);
        public System.Threading.Tasks.Task<int> Simulate(System.CommandLine.Parsing.ParseResult parseResult, Microsoft.Quantum.EntryPointDriver.DriverSettings settings, string simulator) => Microsoft.Quantum.EntryPointDriver.Simulation<global::Walks.TestingStates, QVoid, QVoid>.Simulate(this, this.CreateArgument(parseResult), settings, simulator);
    }
}