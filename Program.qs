namespace Program.Quantum.Oracle {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;

    // This namespace is reserved for Oracles

    // Identity Oracle
    operation MarkingIdentity(register : Qubit[], target : Qubit) : Unit
    is Adj + Ctl {}

    // Zero Oracle
    operation MarkingZero(register : Qubit[], target : Qubit) : Unit
    is Adj + Ctl {
        within {
            ApplyToEachCA(X, register);
        }
        apply {
            Controlled X(register, target);
        }
    }


    // Oracle Conversion
    operation MarkingAsPhase(register : Qubit[], oracle : (Qubit[], Qubit) => Unit is Adj) : Unit
    is Adj {
        use target = Qubit();
        within {
            X(target);
            H(target);
        }
        apply {
            oracle(register, target);
        }
    }

    function MarkingToPhase(oracle : (Qubit[], Qubit) => Unit is Adj) : (Qubit[] => Unit is Adj) {
        return MarkingAsPhase(_, oracle);
    }

    // Test oracle for running Grovers
    // This test checks if a 4-bitstring is either 2, 6 or 14
    operation TestGroverOracle(register : Qubit[], target : Qubit) : Unit
    is Adj {
        // Checking if given register is valid
        Fact(Length(register) == 4, "register is not of correct length");

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

    // Auxillary oracle describing the graph of figure 7
    operation Fig7ExtraMarkingOracle(register : Qubit[], target : Qubit) : Unit
    is Adj + Ctl {
        // Checks if qubit is 000
        within {
            for i in 0..2 {
                X(register[i]);
            }
        }
        apply {
            Controlled X(register, target);
        }

        // Checks if qubit is 011
        within {
            X(register[2]);
        }
        apply {
            Controlled X(register, target);
        }
        // Checks if qubit is 100
        within {
            for i in 0..1 {
                X(register[i]);
            }
        }
        apply {
            Controlled X(register, target);
        }

        // Checks if qubit is 111
        within {

        }
        apply {
            Controlled X(register, target);
        }
    }

    // Oracle marking 101
    operation Marking5(register : Qubit[], target : Qubit) : Unit
    is Adj + Ctl {
        within {
            X(register[1]);
        }
        apply {
            Controlled X(register, target);
        }
    }

}

namespace Program.Quantum.Grovers {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Program.Quantum.Oracle;

    // This namespace is reserved to implement Grover's algorithm

    // One Grover's iterate
    operation GroversIterate(register : Qubit[], phaseOracle : Qubit[] => Unit is Adj) : Unit
    is Adj {
        phaseOracle(register);
        within {
            ApplyToEachCA(H,register);
        }
        apply {
            MarkingToPhase(MarkingZero)(register);
        }
    }

    // Grover's algorithm
    operation GroversAlgorithm(register : Qubit[], phaseOracle : Qubit[] => Unit is Adj, time : Int) : Unit {
        // Initiate initial state
        ApplyToEachCA(H,register);

        // Running Grover's algorithm
        for i in 1..time {
            GroversIterate(register, phaseOracle);
        }
    }

    operation TestGrover() : Int {
        // Create phase oracle
        let phaseOracle = MarkingToPhase(TestGroverOracle);

        // Create initial state
        use reg = Qubit[4];

        // Start Grover's algorithm
        GroversAlgorithm(reg, phaseOracle, 1);

        // Convert Result into Int using binary notation
        mutable ans = 0;
        for i in 0..3 {
            if M(reg[i]) == One {
                set ans = ans + 1*2^i;
            }
        }
        return ans;
    }
}

namespace Program.Quantum.AmplitudeAmplification {
    open Microsoft.Quantum.Core;
    open Microsoft.Quantum.Intrinsic;

    // Amplitude amplification technique
    operation AmplitudeAmplification(register : Qubit[], outputOperator : (Qubit[] => Unit is Adj), phaseOracle : (Qubit[] => Unit is Adj), time : Int) : Unit
    is Adj {
        for i in 1..time {
            outputOperator(register);
            phaseOracle(register);
        }
    }
}

namespace Program.Quantum.Walks {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;

    // open Program.Quantum.Walks.Coins;

    // This namespace is reserved for Quantum Walks

    // Coined models

        // d-regular d-chromatic graphs; position-coin notation
        // For this class of quantum walks, both the coin operator is determined by d and the shift operator is determined by the graph coloring
        operation PoistionCoinWalk(position : Qubit[], color : Qubit[], Shift : ((Qubit[],Qubit[]) => Unit is Adj), Coin : (Qubit[] => Unit is Adj), steps : Int) : Unit
        is Adj {
            for i in 1..steps {
                Coin(color);
                Shift(position, color);
            }
        }

        // Any graph; arc-notation
            // Arc flip-flop operator (MultiSWAP gate)
            operation ArcFlipFlop(present : Qubit[], past : Qubit[]) : Unit
            is Adj {
                // Get qubit length
                let presentSize = Length(present);
                let pastSize = Length(past);

                // past and present qubit size should be the same
                Fact(presentSize == pastSize, "Not a valid format");

                // Switch wires
                for i in 0..(presentSize-1) {
                    SWAP(present[i], past[i]);
                }
            }

        // The coin operator is determined by each nodes neighbors
        operation ArcWalk(present : Qubit[], past : Qubit[], Coin : ((Qubit[],Qubit[]) => Unit is Adj), steps : Int) : Unit
        is Adj {
            for i in 1..steps {
                Coin(present, past);
                ArcFlipFlop(present, past);
            }
        }

    // Uncoined models

        // Staggered model
        // The staggering is determined by the chosen graph tessellation cover
        operation StaggeredWalk(position : Qubit[], Staggering : (Qubit[] => Unit is Adj), steps : Int) : Unit
        is Adj {
            for i in 1..steps {
                Staggering(position);
            }
        }

    // Quantum Search
    operation QuantumSpatialSearch(register : Qubit[],  quantumWalk : (Qubit[], Int) => Unit is Adj, phaseOracle : Qubit[] => Unit is Adj, steps : Int, weight : Int) : Unit
    is Adj {
        // Spatial Search
        for i in 1..steps {
            phaseOracle(register);
            quantumWalk(register, weight);
        }
    }

}

namespace Program.Quantum.Walks.Coins {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;

    open Program.Quantum.Oracle;

    // This namespace is reserved for Coins used in Quantum Walks

    // Grovers coin
    operation GroverCoin(coin : Qubit[]) : Unit
    is Adj {
        let phaseZero = MarkingToPhase(MarkingZero);

        // Conjugate the zero phase oracle into a diagonal state oracle
        within {
            ApplyToEachCA(H, coin);
        }
        apply {
            phaseZero(coin);
            // ApplyToEachCA(Z, coin);
            // ApplyToEachCA(X, coin);
            // ApplyToEachCA(Z, coin);
            // ApplyToEachCA(X, coin);
        }
    }

    // Hadamard coin
    operation HadamardCoin(coin : Qubit[]) : Unit
    is Adj + Ctl {
        ApplyToEachCA(H, coin);
    }

    // Auxillary coin used to traverse the graph of figure 9
    operation Fig9Coin(present : Qubit[], past : Qubit[]) : Unit
    is Adj {
        // Coin at vertex 1
        within {
            for i in 0..1 {
                X(present[i]);
            }
            X(past[0]);
            Controlled X([past[0]], past[1]);
        }
        apply {
            Controlled H(present,past[0]);
        }

        // Coin at vertex 2
        within {
            X(present[1]);
            SWAP(past[0],past[1]);
        }
        apply {
            Controlled H(present, past[0]);
        }

        // Coin at vertex 3
        within {
            X(present[0]);
        }
        apply {
            Controlled HadamardCoin(present, past);
        }

        // Coin at vertex 4
        within {}
        apply {
            Controlled H(present, past[0]);
        }
    }
}

namespace Program.Quantum.Walk.Test {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;

    open Program.Quantum.Oracle;
    open Program.Quantum.Walks;
    open Program.Quantum.Walks.Coins;
    open Program.Quantum.AmplitudeAmplification;

    // Figure 7
    operation Fig7Shift(position : Qubit[], color : Qubit[]) : Unit
    is Adj {
        // Ancilla qubit creation
        use ancilla = Qubit();

        // Making the ancilla witnessing if position is in state 000, 011, 100 or 111
        // The ancilla should only be a witness if coin is 01 or 11
        within { // Witnessing at 01
            X(color[1]);
        }
        apply {
            Controlled Fig7ExtraMarkingOracle(color, (position, ancilla));
        }
        within {// Witnessing at 11
        
        }
        apply {
            Controlled Fig7ExtraMarkingOracle(color, (position, ancilla));
        }

        // Flip-flop operator definition
        X(position[0]);
        Controlled X([color[0]], position[1]);
        Controlled X([color[1]], position[2]);
        Controlled X([ancilla, color[0]], position[2]);

        // Ancilla cleanup
         within { // Witnessing at 01
            X(color[1]);
        }
        apply {
            Controlled Fig7ExtraMarkingOracle(color, (position, ancilla));
        }
        within {// Witnessing at 11
        
        }
        apply {
            Controlled Fig7ExtraMarkingOracle(color, (position, ancilla));
        }
    }

    operation Fig7QuantumWalk(time : Int) : Int {
        // Qubit creation
        use position = Qubit[3];
        use color = Qubit[2];

        // Setting initial state
        ApplyToEachCA(H, position + color);

        // Running quantum walk
        PoistionCoinWalk(position, color, Fig7Shift, GroverCoin, time);

        // Convert Result into Int using binary notation
        mutable ans = 0;
        for i in 0..2 {
            if M(position[i]) == One {
                set ans = ans + 2^i;
            }
        }

        // Cleanup and returning answer
        ResetAll(position + color);
        return ans;
    }

    // Figure 9
    operation Fig9QuantumWalk(time : Int) : Int {
        // Qubit creation
        use present = Qubit[2];
        use past = Qubit[2];

        // Setting initial state
        // ApplyToEachCA(H, present);

            // Setting past to a valid past
            // Setting 0s past to 1 
            within {
                ApplyToEachCA(X, present);
            }
            apply {
                Controlled X(present, past[0]);
            }

            // 1s and 2s past may be zero

            // Setting 4s past to 4
            Controlled X(present, past[0]);
            Controlled X(present, past[1]);


        // Running quantum walk
        ArcWalk(present, past, Fig9Coin, time);

        // Convert Result into Int using binary notation
        mutable ans = 0;
        for i in 0..1 {
            if M(present[i]) == One {
                set ans = ans + 2^i;
            }
        }

        // Cleanup and returning answer
        ResetAll(present + past);
        return ans;
    }

    // Figure 10
    // The Quantum step operator U
    operation Fig10Unitary(qs : Qubit[]) : Unit 
    is Adj + Ctl {
        X(qs[1]);
        Controlled Rz([qs[1], qs[2]], (3.141592653589794, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-2.103300425096747, qs[0]));
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        X(qs[1]);
        Controlled X([qs[0], qs[2]], (qs[1]));
        Controlled Ry([qs[1], qs[2]], (-2.031350318476219, qs[0]));
        X(qs[0]);
        Controlled Ry([qs[0], qs[1]], (-2.171493079730827, qs[2]));
        X(qs[0]);
        X(qs[2]);
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-1.458591923965863, qs[0]));
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        Controlled Ry([qs[0], qs[2]], (-2.218949530948640, qs[1]));
        X(qs[1]);
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-3.030424307027958, qs[0]));
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        X(qs[0]);
        X(qs[1]);
        X(qs[2]);
        Controlled Rz([qs[0], qs[1]], (-3.141592653589793, qs[2]));
        Controlled Ry([qs[0], qs[1]], (-2.392697416712270, qs[2]));
        Controlled Rz([qs[0], qs[1]], (3.141592653589793, qs[2]));
        X(qs[0]);
        X(qs[2]);
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-2.036609034849218, qs[0]));
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Rz([qs[0], qs[2]], (-3.141592653589793, qs[1]));
        Controlled Ry([qs[0], qs[2]], (-1.679368641693380, qs[1]));
        Controlled Rz([qs[0], qs[2]], (-3.141592653589793, qs[1]));
        X(qs[1]);
        X(qs[2]);
        Controlled X([qs[1], qs[2]], (qs[0]));
        X(qs[1]);
        Controlled Ry([qs[0], qs[2]], (-1.803664505052979, qs[1]));
        Controlled Rz([qs[0], qs[2]], (6.283185307179586, qs[1]));
        Controlled Ry([qs[1], qs[2]], (-2.077976459694658, qs[0]));
        X(qs[0]);
        Controlled Ry([qs[0], qs[1]], (-2.313462205161582, qs[2]));
        X(qs[0]);
        X(qs[2]);
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-1.859715331506648, qs[0]));
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        X(qs[1]);
        X(qs[2]);
        Controlled X([qs[1], qs[2]], (qs[0]));
        X(qs[1]);
        Controlled X([qs[0], qs[2]], (qs[1]));
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-1.707019717169139, qs[0]));
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        X(qs[0]);
        Controlled Rz([qs[0], qs[1]], (-3.141592653589793, qs[2]));
        Controlled Ry([qs[0], qs[1]], (-2.171493079730828, qs[2]));
        Controlled Rz([qs[0], qs[1]], (-3.141592653589793, qs[2]));
        X(qs[0]);
        Controlled Ry([qs[0], qs[2]], (-2.465813431258072, qs[1]));
        Controlled Rz([qs[0], qs[2]], (6.283185307179586, qs[1]));
        Controlled Ry([qs[1], qs[2]], (-2.031350318476218, qs[0]));
        Controlled Ry([qs[0], qs[2]], (-2.103300425096748, qs[1]));
        X(qs[1]);
        Controlled X([qs[1], qs[2]], (qs[0]));
        X(qs[1]);
    }

    operation Fig10QuantumWalk(time : Int) : Int {
        // Qubit creation
        use position = Qubit[3];

        // Qubit initialization
        ApplyToEachCA(H,position);

        // Running quantum walk
        StaggeredWalk(position, Fig10Unitary, time);

        // Convert Result into Int using binary notation
        mutable ans = 0;
        for i in 0..2 {
            if M(position[i]) == One {
                set ans = ans + 2^i;
            }
        }

        // Cleanup and returning answer
        ResetAll(position);
        return ans;
    }

    // Auxillary quantum walk operator for the quantum search
    operation AuxillaryFig10QuantumStep(position : Qubit[], weight : Int) : Unit
    is Adj {
        // Running one quantum step
        StaggeredWalk(position, Fig10Unitary, weight);
    }

    operation A (qs : Qubit[]) : Unit
    is Adj {
        Controlled Rz([qs[0], qs[2]], (-3.141592653589793, qs[1]));
        Controlled Ry([qs[0], qs[2]], (-2.626945223647616, qs[1]));
        Controlled Rz([qs[0], qs[2]], (3.141592653589793, qs[1]));
        Controlled X([qs[1], qs[2]], (qs[0]));
        X(qs[0]);
        Controlled Ry([qs[0], qs[1]], (-2.643186335206857, qs[2]));
        X(qs[0]);
        X(qs[2]);
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-2.657980453573126, qs[0]));
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        Controlled Ry([qs[0], qs[2]], (-2.171871618075782, qs[1]));
        X(qs[1]);
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-0.835079605995095, qs[0]));
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        X(qs[1]);
        Controlled Rz([qs[0], qs[2]], (-3.141592653589793, qs[1]));
        Controlled Ry([qs[0], qs[2]], (-2.171871618075782, qs[1]));
        Controlled Rz([qs[0], qs[2]], (-3.141592653589793, qs[1]));
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-2.657980453573126, qs[0]));
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        X(qs[0]);
        X(qs[2]);
        Controlled Rz([qs[0], qs[1]], (-3.141592653589793, qs[2]));
        Controlled Ry([qs[0], qs[1]], (-2.643186335206857, qs[2]));
        Controlled Rz([qs[0], qs[1]], (-3.141592653589793, qs[2]));
        X(qs[0]);
        Controlled Rz([qs[1], qs[2]], (3.141592653589793, qs[0]));
        Controlled Ry([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled Rz([qs[1], qs[2]], (-3.141592653589793, qs[0]));
        Controlled R1([qs[1], qs[2]], (3.141592653589793, qs[0]));
        Controlled Ry([qs[0], qs[2]], (-2.626945223647616, qs[1]));
        Controlled Rz([qs[0], qs[2]], (6.283185307179586, qs[1]));
    }   

    // Let the 5th node in Figure 10 be marked
    operation Fig10QuantumSpatialSearch(time : Int) : Int {
        // Qubit creation
        use position = Qubit[3];

        // Qubit initialization
        ApplyToEachCA(H, position);

        // Running quantum spatial search
        QuantumSpatialSearch(position, AuxillaryFig10QuantumStep, MarkingToPhase(Marking5), time, 1);

        // Running amplitude amplification, for time = 4
        if time == 4 {
            AmplitudeAmplification(position, A, MarkingToPhase(Marking5), 2);
        }

        // Convert Result into Int using binary notation
        mutable ans = 0;
        for i in 0..2 {
            if M(position[i]) == One {
                set ans = ans + 2^i;
            }
        }

        // Cleanup and returning answer
        ResetAll(position);
        return ans;
    }

}

namespace Tests {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;

    open Program.Quantum.Walks.Coins;
    open Program.Quantum.Oracle;
    open Program.Quantum.Walk.Test;

    operation TestFig9Coin() : Unit {
        // Qubit creation
        use present = Qubit[2];
        use past = Qubit[2];

        // Initialize qubits
        X(present[1]);
        X(past[0]);
        X(past[1]);

        // Test operation
        Fig9Coin(present, past);

        // Dump statistics
        DumpRegister("data.html", past);

        // Cleanup
        ResetAll(present + past);
    }

    operation TestFig7ExtraMarkingOracle() : Unit {
        // Qubit creation
        use position = Qubit[3];
        use target = Qubit();

        // Initiate states
        // X(position[0]);
        X(position[1]);
        X(position[2]);

        // Run test
        Fig7ExtraMarkingOracle(position, target);
        Fig7ExtraMarkingOracle(position, target);

        // Dump diagnostics
        DumpRegister("data.html", [target]);

        //
        ResetAll(position + [target]);
    }

    operation TestFig7Shift() : Unit {
        // Qubit creation
        use position = Qubit[3];
        use color = Qubit[2];

        // Qubit initialization
        X(position[0]);
        X(position[1]);
        X(position[2]);
        X(color[0]);
        X(color[1]);

        // Run test
        Fig7Shift(position, color);

        DumpRegister("data.html", position);

        // Cleanup
        ResetAll(position + color);
    }

    operation TestHadamardCoin() : Unit {
        // Qubit creation
        use color= Qubit[2];

        // Qubit initialization

        // Run test
        HadamardCoin(color);

        // Dump data
        // DumpRegister("data.html", color);

        // Cleanup
        ResetAll(color);
    }

    operation SayHello(times : Int) : Unit {
        for i in 1..times {
            Message("Hello");
        }
    }

    operation TestFig10Unitary() : Unit {
        use register = Qubit[3];

        ApplyToEachCA(H, register);

        Fig10Unitary(register);

        // mutable ans = 0;
        // for i in 0..2 {
        //     if M(register[i]) == One {
        //         set ans = ans + 2^i;
        //     }
        // }

        DumpRegister("data.html", register);

        ResetAll(register);
        // return ans;
        
    }

    operation TestGroverCoin() : Unit {
        use register = Qubit[2];

        ApplyToEachCA(X, register);

        GroverCoin(register);

        DumpRegister("data.html", register);

        ResetAll(register);
    }

}

namespace ReportQ {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;

    // Functions are made using the function keyword
    // Functions are pure, i.e. given the input, the output should always be the same
    function HelloWorld() : Unit {
        Message("Hello World!"); // Message : String -> Unit
    }

    // Arguments and output needs to be typed
    function Add(x : Int, y : Int) : Int {
        return x+y;
    }

    // The operation keywords allows impure functions
    // This is necessary in order to allow quantum weirdness
    operation HelloQuantumWorld() : Unit {
        // "use" keyword creates qubits
        // Qubits are initialized in the state |0⟩
        // Qubit() means to create exactly 1 qubit
        use register = Qubit();

        // H is the Hadamard transform, apply H to the register
        H(register);

        // Controlled statements are made using if-else
        // To measure a qubit we use the M function, M : Qubit -> Result
        if M(register) == Zero {
            Message("Hello Quantum World");
        }
        else {
            Message("Bonjour le monde quantique");
        }

        // Before the operation is ended, every qubit created in the operation needs to be released
        // A qubit is released if it is in the state it was initialized in
        // We use Reset to send a qubit to the state |0⟩
        Reset(register);
    }

    operation HelloMultiQuantumWorld() : Unit {
        // The keyword Qubit[n] creates n qubits
        use register = Qubit[2];

        // This function applies H to each qubit, see documentation for more info
        ApplyToEachCA(H, register);

        // There are two ways to initialize variables
        // let keywords creates immutable objects, they may not be changed
        let a = 2;

        // mutable keywords creates mutable objects, they may be changed using the set keyword
        mutable num = 0;
        
        // For loops are used to iterate over an iterable object
        // Repeat loops are used instead of while loops for conditional iteration, see documentation for more info
        // While loops may be used safely within function statements
        for i in 0..1 {
            if M(register[i]) == One {
                // We use set to change num
                set num = num + 2^i;
            }
        }

        // Bigger if-else blocks may be constructed with elif
        if num == 0 {
            Message("Hello Quantum World!");
        }
        elif num == 1 {
            Message("Bonjour le monde quantique!");
        }
        elif num == 2 {
            Message("สวัสดีโลกควอนตัม!");
        }
        else {
            Message("今日は量子世界!");
        }
    }

    operation MoreOnOperators() : Unit {
        // Single qubit operators
            // Create a qubit in state |0⟩
            use q = Qubit();

            // We have the Pauli matrices, X, Y, Z
            X(q);
            Y(q);
            Z(q);

            // The Hadamard transform
            H(q);

            // Rotation transforms, around the x, y and z axis respectively
            // We need a double to set the operator
            let theta = 1.57;
            Rx(theta, q);
            Ry(theta, q);
            Rz(theta, q);

            // The π/4 and π/8 phase operator
            S(q);
            T(q);

        // Multi qubit operators
            // Create qubits in state |00⟩
            use qs = Qubit[3];

            // Controlled not gate
            CNOT(qs[0],qs[1]);

            // SWAP gate
            SWAP(qs[0],qs[1]);

            // Some operator have the Controlled or Ctl property
            // These operators may be controlled or multi-controlled with the keyword Controll

            // Controlled Hadamard
            Controlled H([qs[0]],qs[1]);

            // Multicontrolled Pauli X
            // This is the same as CCNOT
            Controlled X([qs[0],qs[1]],qs[2]);

        // Conjugated operators
            // Some operators have the Adjoint or Adj property
            // Operators with this property may be auto inverted (see docs to see how to implement this property by hand)
            
            // This auto-inversion allows us to conjugate an operator
            // An operator A is conjugated by B whenever we do BAB⁻¹
            // Conjugation is done in Q# with a within-apply block
            // Within represents B and apply represents A
            within {
                X(q);
            }
            apply {
                H(q);
            }

            // This is the same as:
            // (Note that X is hermitian, so X = X⁻¹)
            X(q);
            H(q);
            X(q);
    }

    // An operation is defined to have the Adjoint property if it returns type Unit is Adj
    // It is defined to have the Controlled property if it returns the type Unit is Ctl
    // It has both property if it returns the type Unit is Adj + Ctl
    operation AdjointAndControlled(target : Qubit) : Unit
    is Adj + Ctl {
        H(target);
    }

}
