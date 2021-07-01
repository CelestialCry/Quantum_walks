namespace Walks {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation SayHello() : Unit {
        use qbit = Qubit();
        H(qbit);
        if MResetZ(qbit) == Zero {
            Message("Hello quantum world!");
        }
        else {
            Message("Hi quantum world!");
        }
    }
}


