namespace Walks {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert as Convert;
    
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

    // Oracle definitions
    
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
        operation GroversAlgorithm(register : Qubit[], markingOracle : ((Qubit[],Qubit) => Unit is Adj), k : Int) : Unit {
            let phaseOracle = PhaseOracle(markingOracle);
            // use register = Qubit[N];
            ApplyToEachCA(H, register);

            for i in 1..k {
                GroversIterate(register, phaseOracle);
            }
        }

        operation OppositePhaseShift(qubit : Qubit) : Unit is Adj + Ctl {
            within {
                X(qubit);
            }
            apply {
                Z(qubit);
            }
        }

        // An oracle which takes a 4-qubit input and checks if it is an answer to 0010001000000010 (2,6,14)
        operation ExampleOracle(register : Qubit[], target : Qubit) : Unit
        is Adj {
            Fact(Length(register) == 4, "This is not a valid input");

            // Checks if the input qubit is a 2
            within {
                X(register[3]);
                X(register[2]);
                X(register[0]);
            }
            apply {
                Controlled X(register, target);
            }

            // Checks if the input qubit is a 6
            within {
                X(register[3]);
                X(register[0]);
            }
            apply {
                Controlled X(register, target);
            }

            // Checks if the input qubit is a 14
            within {
                X(register[0]);
            }
            apply {
                Controlled X(register, target);
            }
        }

        // Testing Grover on ExampleOracle
        @EntryPoint()
        operation GroverTest() : Int {
            use reg = Qubit[4];
            GroversAlgorithm(reg, ExampleOracle, 1);
            mutable ans = 0;
            for i in 0..3 {
                if M(reg[i]) == One {
                    set ans = ans + 1*2^i;
                }
            }
            return ans;
        }

    // Coin definitions goes here
        operation GroverCoin(coin : Qubit[]) : Unit is Adj {
            // Defining the correct phase oracle
            let AllZerosPhaseOracle = PhaseOracle(AllZerosOracle);
            
            // Conjugating AllZerosPhaseOracle to DiagonalStatePhaseOracle
            within {
                ApplyToEachA(H, coin);
            }
            apply {
                AllZerosPhaseOracle(coin);
            }            
        }

        

    // Quantum walk algorithm goes here
        //The quantum walk algorithm uses arcs to traverse a graph. For a graph G=(V,E), we will let the algorithm work on the space ℂV⊗ℂV.
        // The elements which we will operate on live inside ℂ(E∐E)⊆ℂV⊗ℂV. Thus in order to define unitary transformations,
        // it suffices to define unitary transformations on tensors, and check that it is correct when restricting to the appropriate subspace.

        // The flip-flopping shift operator on arcs, described on tensors
        operation ArcFlipFlop(x : Qubit[], y : Qubit[]) : Unit is Adj {
            let (m, n) = (Length(x), Length(y));
            Fact(m == n, "Dimensjons of registers are unequal");

            for i in 0..m-1 {
                CNOT(x[i],y[i]);
                CNOT(y[i],x[i]);
            }
        }

        // Defining Quantum walks on tensors
        // First the coin is flipped, and then we walk accordingly to which of the many faces the coin may have landed on.
        operation QuantumArcStep(uTens : Qubit[], vTens : Qubit[], shift : ((Qubit[], Qubit[]) => Unit is Adj), coin : ((Qubit[], Qubit[]) => Unit is Adj)) : Unit is Adj {
            coin(uTens, vTens);
            shift(uTens, vTens);
        }

        // Defining a global quantum walk
        // Non-queried walk is obtained by applying the identity oracle
        operation QuantumArcWalk(uTens : Qubit[], vTens : Qubit[], shift : ((Qubit[], Qubit[]) => Unit is Adj), coin : ((Qubit[],Qubit[]) => Unit is Adj), oracle : ((Qubit[], Qubit) => Unit is Adj), k : Int) : Unit is Adj {
            // Checkinng if workspace assumptions are correct
            let (m,n) = (Length(uTens),Length(vTens));
            Fact(m == n, "Ill-defined workspace!");

            ApplyToEachCA(H, uTens);
            ApplyToEachCA(H, vTens);

            // Running walking algorithm
            let phaseOracle = PhaseOracle(oracle);
            
            for i in 1..k {
                phaseOracle(uTens + vTens);
                QuantumArcStep(uTens, vTens, shift, coin);
            }
        }

    // Trying to model a quantum walk on a 3-regular graph with 8 vertices. It look kinda like 2 kites melded together.
    operation OddVertexOracle(pos : Qubit[], color : Qubit[], target : Qubit) : Unit
    is Adj + Ctl {
        // This oracle should only tag if color = 11
        
        // Checks if pos = 000
        within {
            ApplyToEachCA(X, pos);
        }
        apply {
            Controlled X(pos+color, target);
        }

        // Checks if pos = 111
        Controlled X(pos+color, target);

        // Checks if pos = 011
        within {
            X(pos[2]);
        }
        apply {
            Controlled X(pos+color, target);
        }

        // Checks if pos = 100
        within {
            X(pos[0]);
            X(pos[1]);
        }
        apply {
            Controlled X(pos+color, target);
        }
    }
    
    operation ExampleFlipFlop(pos : Qubit[], color : Qubit[]) : Unit
    is Adj + Ctl {
        use anc = Qubit();
        OddVertexOracle(pos, color, anc);
        Controlled X([color[0]], pos[0]);
        Controlled X([color[1]], pos[1]);
        Controlled X([anc], pos[2]);
        OddVertexOracle(pos, color, anc);
    }

    operation ExampleMark(pos : Qubit[], target : Qubit) : Unit
    is Adj + Ctl {
        // Marks 101
        within {
            X(pos[1]);
        }   
        apply {
            Controlled X(pos, target);
        }
    }

    // Test av vandring på eksempel graf
    // @EntryPoint()
    operation Test() : Int {
        use pos = Qubit[3];
        use color = Qubit[2];
        let ExampleCoin = ApplyToEachCA(H, _);
        let phaseOracle = PhaseOracle(ExampleMark);

        // Initialiserer til en startposisjon som er uniformt fordelt
        ApplyToEachCA(H, pos);

        // Denne virker etter 8 iterasjoner, hvorfor?
        for i in 1..8 {
            phaseOracle(pos);
            ExampleCoin(color);
            ExampleFlipFlop(pos, color);
        }

        mutable ans = 0;
        for i in 0..2 {
            if M(pos[i]) == One {
                set ans = ans + 1*2^i;
            }
        }
        ResetAll(color);
        return ans;
    }
}


