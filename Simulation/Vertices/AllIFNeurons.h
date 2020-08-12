/**
 *      @file AllIFNeurons.h
 *
 *      @brief A container of all Integate and Fire (IF) neuron data
 */

/** 
 ** @authors Aaron Oziel, Sean Blackbourn
 **
 ** @class AllIFNeurons AllIFNeurons.h "AllIFNeurons.h"
 **
 ** \latexonly  \subsubsection*{Implementation} \endlatexonly
 ** \htmlonly   <h3>Implementation</h3> \endhtmlonly
 **
 ** A container of all Integate and Fire (IF) neuron data.
 ** This is the base class of all Integate and Fire (IF) neuron classes.
 **
 ** The class uses a data-centric structure, which utilizes a structure as the containers of
 ** all neuron.
 **
 ** The container holds neuron parameters of all neurons.
 ** Each kind of neuron parameter is stored in a 1D array, of which length
 ** is number of all neurons. Each array of a neuron parameter is pointed by a
 ** corresponding member variable of the neuron parameter in the class.
 **
 ** This structure was originally designed for the GPU implementation of the
 ** simulator, and this refactored version of the simulator simply uses that design for
 ** all other implementations as well. This is to simplify transitioning from
 ** single-threaded to multi-threaded.
 **
 ** \latexonly  \subsubsection*{Credits} \endlatexonly
 ** \htmlonly   <h3>Credits</h3> \endhtmlonly
 **
 ** Some models in this simulator is a rewrite of CSIM (2006) and other
 ** work (Stiber and Kawasaki (2007?))
 **
 **/
#pragma once

#include "Global.h"
#include "AllSpikingNeurons.h"

struct AllIFNeuronsDeviceProperties;

class AllIFNeurons : public AllSpikingNeurons {
public:
   AllIFNeurons();

   virtual ~AllIFNeurons();

   /**
    *  Setup the internal structure of the class.
    *  Allocate memories to store all neurons' state.
    *
    *  @param  sim_info  SimulationInfo class to read information from.
    */
   virtual void setupNeurons();

   /**
    *  Cleanup the class.
    *  Deallocate memories.
    */
   virtual void cleanupNeurons();

   /// Load member variables from configuration file. Registered to OperationManager as Operation::op::loadParameters
   virtual void loadParameters();

   /**
    *  Prints out all parameters of the neurons to console.
    */
   virtual void printParameters() const;

   /**
    *  Creates all the Neurons and assigns initial data for them.
    *
    *  @param  sim_info    SimulationInfo class to read information from.
    *  @param  layout      Layout information of the neunal network.
    */
   virtual void createAllNeurons(Layout *layout);

   /**
    *  Outputs state of the neuron chosen as a string.
    *
    *  @param  i   index of the neuron (in neurons) to output info from.
    *  @return the complete state of the neuron.
    */
   virtual string toString(const int i) const;

   /**
    *  Reads and sets the data for all neurons from input stream.
    *
    *  @param  input       istream to read from.
    *  @param  sim_info    used as a reference to set info for neuronss.
    */
   virtual void deserialize(istream &input);

   /**
    *  Writes out the data in all neurons to output stream.
    *
    *  @param  output      stream to write out to.
    *  @param  sim_info    used as a reference to set info for neuronss.
    */
   virtual void serialize(ostream &output) const;

#if defined(USE_GPU)
   public:
       /**
        *  Update the state of all neurons for a time step
        *  Notify outgoing synapses if neuron has fired.
        *
        *  @param  synapses               Reference to the allSynapses struct on host memory.
        *  @param  allNeuronsDevice       Reference to the allNeurons struct on device memory.
        *  @param  allSynapsesDevice      Reference to the allSynapses struct on device memory.
        *  @param  sim_info               SimulationInfo to refer from.
        *  @param  randNoise              Reference to the random noise array.
        *  @param  synapseIndexMapDevice  Reference to the SynapseIndexMap on device memory.
        */
       virtual void advanceNeurons(IAllSynapses &synapses, void* allNeuronsDevice, void* allSynapsesDevice, const SimulationInfo *sim_info, float* randNoise, SynapseIndexMap* synapseIndexMapDevice);

       /**
        *  Allocate GPU memories to store all neurons' states,
        *  and copy them from host to GPU memory.
        *
        *  @param  allNeuronsDevice   Reference to the allNeurons struct on device memory.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       virtual void allocNeuronDeviceStruct( void** allNeuronsDevice, SimulationInfo *sim_info );

       /**
        *  Delete GPU memories.
        *
        *  @param  allNeuronsDevice   Reference to the allNeurons struct on device memory.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       virtual void deleteNeuronDeviceStruct( void* allNeuronsDevice, const SimulationInfo *sim_info );

       /**
        *  Copy all neurons' data from host to device.
        *
        *  @param  allNeuronsDevice   Reference to the allNeurons struct on device memory.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       virtual void copyNeuronHostToDevice( void* allNeuronsDevice, const SimulationInfo *sim_info );

       /**
        *  Copy all neurons' data from device to host.
        *
        *  @param  allNeuronsDevice   Reference to the allNeurons struct on device memory.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       virtual void copyNeuronDeviceToHost( void* allNeuronsDevice, const SimulationInfo *sim_info );

       /**
        *  Copy spike history data stored in device memory to host.
        *
        *  @param  allNeuronsDevice   Reference to the allNeurons struct on device memory.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       virtual void copyNeuronDeviceSpikeHistoryToHost( void* allNeuronsDevice, const SimulationInfo *sim_info );

       /**
        *  Copy spike counts data stored in device memory to host.
        *
        *  @param  allNeuronsDevice   Reference to the allNeurons struct on device memory.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       virtual void copyNeuronDeviceSpikeCountsToHost( void* allNeuronsDevice, const SimulationInfo *sim_info );

       /**
        *  Clear the spike counts out of all neurons.
        *
        *  @param  allNeuronsDevice   Reference to the allNeurons struct on device memory.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       virtual void clearNeuronSpikeCounts( void* allNeuronsDevice, const SimulationInfo *sim_info );

   protected:
       /**
        *  Allocate GPU memories to store all neurons' states.
        *  (Helper function of allocNeuronDeviceStruct)
        *
        *  @param  allNeurons         Reference to the AllIFNeuronsDeviceProperties struct.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       void allocDeviceStruct( AllIFNeuronsDeviceProperties &allNeurons, SimulationInfo *sim_info );

       /**
        *  Delete GPU memories.
        *  (Helper function of deleteNeuronDeviceStruct)
        *
        *  @param  allNeurons         Reference to the AllIFNeuronsDeviceProperties struct.
        *  @param  sim_info           SimulationInfo to refer from.
        */
       void deleteDeviceStruct( AllIFNeuronsDeviceProperties& allNeurons, const SimulationInfo *sim_info );

       /**
        *  Copy all neurons' data from host to device.
        *  (Helper function of copyNeuronHostToDevice)
        *
        *  @param  allNeurons         Reference to the AllIFNeuronsDeviceProperties struct.
        *  @param  sim_info           SimulationInfo to refer from.
        */
  void copyHostToDevice( AllIFNeuronsDeviceProperties& allNeurons, const SimulationInfo *sim_info );

       /**
        *  Copy all neurons' data from device to host.
        *  (Helper function of copyNeuronDeviceToHost)
        *
        *  @param  allNeurons         Reference to the AllIFNeuronsDeviceProperties struct.
        *  @param  sim_info           SimulationInfo to refer from.
        */
  void copyDeviceToHost( AllIFNeuronsDeviceProperties& allNeurons, const SimulationInfo *sim_info );

#endif // defined(USE_GPU)

protected:
   /**
    *  Creates a single Neuron and generates data for it.
    *
    *  @param  sim_info     SimulationInfo class to read information from.
    *  @param  neuron_index Index of the neuron to create.
    *  @param  layout       Layout information of the neunal network.
    */
   void createNeuron(int neuron_index, Layout *layout);

   /**
    *  Set the Neuron at the indexed location to default values.
    *
    *  @param  neuron_index    Index of the Neuron that the synapse belongs to.
    */
   void setNeuronDefaults(const int index);

   /**
    *  Initializes the Neuron constants at the indexed location.
    *
    *  @param  neuron_index    Index of the Neuron.
    *  @param  deltaT          Inner simulation step duration
    */
   virtual void initNeuronConstsFromParamValues(int neuron_index, const BGFLOAT deltaT);

   /**
    *  Sets the data for Neuron #index to input's data.
    *
    *  @param  input       istream to read from.
    *  @param  sim_info    used as a reference to set info for neurons.
    *  @param  i           index of the neuron (in neurons).
    */
   void readNeuron(istream &input, int i);

   /**
    *  Writes out the data in the selected Neuron.
    *
    *  @param  output      stream to write out to.
    *  @param  sim_info    used as a reference to set info for neuronss.
    *  @param  i           index of the neuron (in neurons).
    */
   void writeNeuron(ostream &output, int i) const;

private:
   /**
    *  Deallocate all resources
    */
   void freeResources();

public:
   /**
    *  The length of the absolute refractory period. [units=sec; range=(0,1);]
    */
   BGFLOAT *Trefract_;

   /**
    *  If \f$V_m\f$ exceeds \f$V_{thresh}\f$ a spike is emmited. [units=V; range=(-10,100);]
    */
   BGFLOAT *Vthresh_;

   /**
    *  The resting membrane voltage. [units=V; range=(-1,1);]
    */
   BGFLOAT *Vrest_;

   /**
    *  The voltage to reset \f$V_m\f$ to after a spike. [units=V; range=(-1,1);]
    */
   BGFLOAT *Vreset_;

   /**
    *  The initial condition for \f$V_m\f$ at time \f$t=0\f$. [units=V; range=(-1,1);]
    */
   BGFLOAT *Vinit_;

   /**
    *  The membrane capacitance \f$C_m\f$ [range=(0,1); units=F;]
    *  Used to initialize Tau (no use after that)
    */
   BGFLOAT *Cm_;

   /**
    *  The membrane resistance \f$R_m\f$ [units=Ohm; range=(0,1e30)]
    */
   BGFLOAT *Rm_;

   /**
    * The standard deviation of the noise to be added each integration time constant. [range=(0,1); units=A;]
    */
   BGFLOAT *Inoise_;

   /**
    *  A constant current to be injected into the LIF neuron. [units=A; range=(-1,1);]
    */
   BGFLOAT *Iinject_;

   /**
    * What the hell is this used for???
    *  It does not seem to be used; seems to be a candidate for deletion.
    *  Possibly from the old code before using a separate summation point
    *  The synaptic input current.
    */
   BGFLOAT *Isyn_;

   /**
    * The remaining number of time steps for the absolute refractory period.
    */
   int *numStepsInRefractoryPeriod_;

   /**
    * Internal constant for the exponential Euler integration of f$V_m\f$.
    */
   BGFLOAT *C1_;

   /**
    * Internal constant for the exponential Euler integration of \f$V_m\f$.
    */
   BGFLOAT *C2_;

   /**
    * Internal constant for the exponential Euler integration of \f$V_m\f$.
    */
   BGFLOAT *I0_;

   /**
    * The membrane voltage \f$V_m\f$ [readonly; units=V;]
    */
   BGFLOAT *Vm_;

   /**
    * The membrane time constant \f$(R_m \cdot C_m)\f$
    */
   BGFLOAT *Tau_;

private:
   /**
    * Min/max values of Iinject.
    */
   BGFLOAT IinjectRange_[2];

   /**
    * Min/max values of Inoise.
    */
   BGFLOAT InoiseRange_[2];

   /**
    * Min/max values of Vthresh.
    */
   BGFLOAT VthreshRange_[2];

   /**
    * Min/max values of Vresting.
    */
   BGFLOAT VrestingRange_[2];

   /**
    * Min/max values of Vreset.
    */
   BGFLOAT VresetRange_[2];

   /**
    * Min/max values of Vinit.
    */
   BGFLOAT VinitRange_[2];

   /**
    * Min/max values of Vthresh.
    */
   BGFLOAT starterVthreshRange_[2];

   /**
    * Min/max values of Vreset.
    */
   BGFLOAT starterVresetRange_[2];
};

#if defined(USE_GPU)
struct AllIFNeuronsDeviceProperties : public AllSpikingNeuronsDeviceProperties
{
        /**
         *  The length of the absolute refractory period. [units=sec; range=(0,1);]
         */
        BGFLOAT *Trefract_;

        /**
         *  If \f$V_m\f$ exceeds \f$V_{thresh}\f$ a spike is emmited. [units=V; range=(-10,100);]
         */
        BGFLOAT *Vthresh_;

        /**
         *  The resting membrane voltage. [units=V; range=(-1,1);]
         */
        BGFLOAT *Vrest_;

        /**
         *  The voltage to reset \f$V_m\f$ to after a spike. [units=V; range=(-1,1);]
         */
        BGFLOAT *Vreset_;

        /**
         *  The initial condition for \f$V_m\f$ at time \f$t=0\f$. [units=V; range=(-1,1);]
         */
        BGFLOAT *Vinit_;

        /**
         *  The membrane capacitance \f$C_m\f$ [range=(0,1); units=F;]
         *  Used to initialize Tau (no use after that)
         */
        BGFLOAT *Cm_;

        /**
         *  The membrane resistance \f$R_m\f$ [units=Ohm; range=(0,1e30)]
         */
        BGFLOAT *Rm_;

        /**
         * The standard deviation of the noise to be added each integration time constant. [range=(0,1); units=A;]
         */
        BGFLOAT *Inoise_;

        /**
         *  A constant current to be injected into the LIF neuron. [units=A; range=(-1,1);]
         */
        BGFLOAT *Iinject_;

        /**
         * What the hell is this used for???
         *  It does not seem to be used; seems to be a candidate for deletion.
         *  Possibly from the old code before using a separate summation point
         *  The synaptic input current.
         */
        BGFLOAT *Isyn_;

        /**
         * The remaining number of time steps for the absolute refractory period.
         */
        int *numStepsInRefractoryPeriod_;

        /**
         * Internal constant for the exponential Euler integration of f$V_m\f$.
         */
        BGFLOAT *C1_;

        /**
         * Internal constant for the exponential Euler integration of \f$V_m\f$.
         */
        BGFLOAT *C2_;

        /**
         * Internal constant for the exponential Euler integration of \f$V_m\f$.
         */
        BGFLOAT *I0_;

        /**
         * The membrane voltage \f$V_m\f$ [readonly; units=V;]
         */
        BGFLOAT *Vm_;

        /**
         * The membrane time constant \f$(R_m \cdot C_m)\f$
         */
        BGFLOAT *Tau_;
};
#endif // defined(USE_GPU)