namespace Walks {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Math;
    
    // @EntryPoint()
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

    // Oracle definitions goes here
    
        // The identity Oracle, it does nothing!
        operation IdentityOracle(register : Qubit[], target : Qubit) : Unit
        is Adj {}

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

    // Grover's algorithm

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
    // First the coin is flipped, and then we walk accordingly to which of the many faces the coin may have landed on.
    operation QuantumStep(uTens : Qubit[], vTens : Qubit[], shift : ((Qubit[], Qubit[]) => Unit is Adj), coin : ((Qubit[], Qubit[]) => Unit is Adj)) : Unit is Adj {
        coin(uTens, vTens);
        // DumpMachine();
        shift(uTens, vTens);
    }

    // Defining a global quantum walk
    // Non-queried walk is obtained by applying the identity oracle
    operation QuantumWalk(uTens : Qubit[], vTens : Qubit[], shift : ((Qubit[], Qubit[]) => Unit is Adj), coin : ((Qubit[],Qubit[]) => Unit is Adj), oracle : ((Qubit[], Qubit) => Unit is Adj), k : Int) : Unit is Adj {
        // Initializing workspace
        // use uTens = Qubit[n];
        // use vTens = Qubit[n];
        let (m,n) = (Length(uTens),Length(vTens));
        Fact(m == n, "Ill-defined workspace!");
        ApplyToEachCA(H, uTens);
        ApplyToEachCA(H, vTens);

        // Running walking algorithm
        let phaseOracle = PhaseOracle(oracle);
        
        for i in 1..k {
            phaseOracle(uTens + vTens);
            QuantumStep(uTens, vTens, shift, coin);
        }
    }
    
    // Quantum walk on K_4 with loops
    // K_4 has 4 vertices, these may be encoded as |00⟩, |01⟩, |10⟩ and |11⟩
    // On each vertex there are three edges, they may each be given a color: red, yellow, blue or magenta (|00⟩, |01⟩, |10⟩ and |11⟩)
    // NB! In this test we allow an edge from a vertex to itself.
    // An edge from |00⟩ to |01⟩ is written as |00⟩⊗|01⟩

    // Set a qbit in |00⟩ into the state 1 / sqrt(3) (|00⟩ + |01⟩ + |10⟩)
    operation ThreeStates(qs : Qubit[]) : Unit is Adj {
        // Rotate first qbit to (sqrt(2) |0) + |1⟩) / sqrt(3)
        let theta = ArcSin(1.0 / Sqrt(3.0));
        Ry(2.0 * theta, qs[0]);

        // Split the state sqrt(2) |0⟩ ⊗ |0⟩ into |00⟩ + |01⟩
        within {
            X(qs[0]);
        }
        apply {
            Controlled H([qs[0]], qs[1]);
        }
    }

    operation K4Coin(uTens : Qubit[], vTens : Qubit[]) : Unit is Adj {
        // Check well-definedness
        let (m, n) = (Length(uTens), Length(vTens));
        Fact(m == n and n == 2, "This does not represent K4 :(:(::(");

        // Coin operation
        ApplyToEachCA(H,vTens);
        
    }

    @EntryPoint()
    operation TestingStates() : Unit {
        use uTens = Qubit[2];
        use vTens = Qubit[2];

        QuantumWalk(uTens, vTens, FlipFlop, K4Coin, IdentityOracle, 12);
        DumpMachine();
        ResetAll(uTens + vTens);
    }


}


