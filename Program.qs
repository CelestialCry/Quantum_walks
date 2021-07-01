namespace Walks {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
    
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

    // Grover's algorithm goes here

    // A marking oracle which flips the target bit if the register is |0..0>
    operation AllZerosOracle(register : Qubit[], target : Qubit) : Unit is Adj {
        within {
            ApplyToEachCA(X,register);
        }
        apply {
            Controlled X(register, target);
        }
    }

    // This operation takes a marking oracle and applies the operation which gives it the form of a phase oracle
    operation ConversionTherapy(register : Qubit[], oracle : ((Qubit[],Qubit) => Unit is Adj)) : Unit is Adj {
        use target = Qubit();
        within {
            X(target);
            H(target);
        }
        apply {
            oracle(register, target);
        }
    }

    // This function takes a marking oracle and converts it to a phase oracle
    function PhaseOracle(markingOracle : ((Qubit[],Qubit) => Unit is Adj)) : (Qubit[] => Unit is Adj) {
        return ConversionTherapy(_,markingOracle);
    }

    operation GroversIterate(register : Qubit[], phaseOracle : (Qubit[] => Unit is Adj)) : Unit is Adj {
        phaseOracle(register);
        within {
            ApplyToEachCA(H, register);
        }
        apply {
            PhaseOracle(AllZerosOracle)(register);
        }
    }

    // Grovers algorithm (without corrections)
    operation GroversAlgorithm(markingOracle : ((Qubit[],Qubit) => Unit is Adj), N : Int, k : Int) : Unit {
        let phaseOracle = PhaseOracle(markingOracle);
        use register = Qubit[N];
        ApplyToEachCA(H, register);

        for i in 1..k {
            GroversIterate(register, phaseOracle);
        }
    }

    // Quantum walk algorithm goes here
        //The quantum walk algorithm uses arcs to traverse a graph. For a graph G=(V,E), we will let the algorithm work on the space ℂV⊗ℂV.
        // The elements which we will operate on live inside ℂ(E∐E)⊆ℂV⊗ℂV. Thus in order to define unitary transformations,
        // it suffices to define unitary transformations on tensors, and check that it is correct when restricting to the appropriate subspace.

    // The flip-flopping shift operator, described on tensors
    operation FlipFlop(x : Qubit[], y : Qubit[]) : Unit is Adj {
        let (m, n) = (Length(x), Length(y));
        Fact(m == n, "Dimensjons of registers are unequal");

        for i in 0..m-1 {
            CNOT(x[i],y[i]);
            CNOT(y[i],x[i]);
        }
    }

    // Defining Quantum walks on tensors
    operation QuantumWalk(firstTensor : Qubit[], secondTensor : Qubit[], shift : ((Qubit[], Qubit[]) => Unit is Adj), coin : ((Qubit[],Qubit[]) => Unit is Adj), k : Int) : Unit is Adj {
        for i in 1..k {
            coin(firstTensor, secondTensor);
            shift(firstTensor, secondTensor);
        }
    }
    
}


