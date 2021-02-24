/**
 * @file AllSpikingSynapses_d.cu
 * 
 * @ingroup Simulator/Edges
 *
 * @brief
 */

#include "AllSpikingSynapses.h"
#include "AllSynapsesDeviceFuncs.h"
#include "Book.h"

///  Allocate GPU memories to store all synapses' states,
///  and copy them from host to GPU memory.
///
///  @param  allEdgesDevice  GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                             on device memory.
void AllSpikingSynapses::allocSynapseDeviceStruct( void** allEdgesDevice ) {
        allocSynapseDeviceStruct( allEdgesDevice, Simulator::getInstance().getTotalVertices(), Simulator::getInstance().getMaxSynapsesPerNeuron() );
}

///  Allocate GPU memories to store all synapses' states,
///  and copy them from host to GPU memory.
///
///  @param  allEdgesDevice     GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                                on device memory.
///  @param  numVertices            Number of vertices.
///  @param  maxEdgesPerVertex  Maximum number of synapses per neuron.
void AllSpikingSynapses::allocSynapseDeviceStruct( void** allEdgesDevice, int numVertices, int maxEdgesPerVertex ) {
        AllSpikingSynapsesDeviceProperties allSynapses;

        allocDeviceStruct( allSynapses, numVertices, maxEdgesPerVertex );

        HANDLE_ERROR( cudaMalloc( allEdgesDevice, sizeof( AllSpikingSynapsesDeviceProperties ) ) );
        HANDLE_ERROR( cudaMemcpy ( *allEdgesDevice, &allSynapses, sizeof( AllSpikingSynapsesDeviceProperties ), cudaMemcpyHostToDevice ) );
}

///  Allocate GPU memories to store all synapses' states,
///  and copy them from host to GPU memory.
///  (Helper function of allocSynapseDeviceStruct)
///
///  @param  allEdgesDevice     GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                                on device memory.
///  @param  numVertices            Number of vertices.
///  @param  maxEdgesPerVertex  Maximum number of synapses per neuron.
void AllSpikingSynapses::allocDeviceStruct( AllSpikingSynapsesDeviceProperties &allEdgesDevice, int numVertices, int maxEdgesPerVertex ) {
        BGSIZE maxTotalSynapses = maxEdgesPerVertex * numVertices;

        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.sourceNeuronIndex_, maxTotalSynapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.destNeuronIndex_, maxTotalSynapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.W_, maxTotalSynapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.type_, maxTotalSynapses * sizeof( synapseType ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.psr_, maxTotalSynapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.inUse_, maxTotalSynapses * sizeof( bool ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.synapseCounts_, numVertices * sizeof( BGSIZE ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.decay_, maxTotalSynapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.tau_, maxTotalSynapses * sizeof( BGFLOAT ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.totalDelay_, maxTotalSynapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.delayQueue_, maxTotalSynapses * sizeof( uint32_t ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.delayIndex_, maxTotalSynapses * sizeof( int ) ) );
        HANDLE_ERROR( cudaMalloc( ( void ** ) &allEdgesDevice.delayQueueLength_, maxTotalSynapses * sizeof( int ) ) );
}

///  Delete GPU memories.
///
///  @param  allEdgesDevice  GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                             on device memory.
void AllSpikingSynapses::deleteSynapseDeviceStruct( void* allEdgesDevice ) {
        AllSpikingSynapsesDeviceProperties allSynapses;

        HANDLE_ERROR( cudaMemcpy ( &allSynapses, allEdgesDevice, sizeof( AllSpikingSynapsesDeviceProperties ), cudaMemcpyDeviceToHost ) );

        deleteDeviceStruct( allSynapses );

        HANDLE_ERROR( cudaFree( allEdgesDevice ) );
}

///  Delete GPU memories.
///  (Helper function of deleteSynapseDeviceStruct)
///
///  @param  allEdgesDevice  GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                             on device memory.
void AllSpikingSynapses::deleteDeviceStruct( AllSpikingSynapsesDeviceProperties& allEdgesDevice ) {
        HANDLE_ERROR( cudaFree( allEdgesDevice.sourceNeuronIndex_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.destNeuronIndex_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.W_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.type_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.psr_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.inUse_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.synapseCounts_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.decay_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.tau_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.totalDelay_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.delayQueue_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.delayIndex_ ) );
        HANDLE_ERROR( cudaFree( allEdgesDevice.delayQueueLength_ ) );

        // Set countVertices_ to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        //allSynapses.countVertices_ = 0;
}

///  Copy all synapses' data from host to device.
///
///  @param  allEdgesDevice  GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                             on device memory.
void AllSpikingSynapses::copySynapseHostToDevice( void* allEdgesDevice ) { // copy everything necessary
        copySynapseHostToDevice( allEdgesDevice, Simulator::getInstance().getTotalVertices(), Simulator::getInstance().getMaxSynapsesPerNeuron() );
}

///  Copy all synapses' data from host to device.
///
///  @param  allEdgesDevice     GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                                on device memory.
///  @param  numVertices            Number of vertices.
///  @param  maxEdgesPerVertex  Maximum number of synapses per neuron.
void AllSpikingSynapses::copySynapseHostToDevice( void* allEdgesDevice, int numVertices, int maxEdgesPerVertex ) { // copy everything necessary
        AllSpikingSynapsesDeviceProperties allEdgesDeviceProps;

        HANDLE_ERROR( cudaMemcpy ( &allEdgesDeviceProps, allEdgesDevice, sizeof( AllSpikingSynapsesDeviceProperties ), cudaMemcpyDeviceToHost ) );

        copyHostToDevice( allEdgesDevice, allEdgesDeviceProps, numVertices, maxEdgesPerVertex );
}

///  Copy all synapses' data from host to device.
///  (Helper function of copySynapseHostToDevice)
///
///  @param  allEdgesDevice           GPU address of the allSynapses struct on device memory.     
///  @param  allEdgesDeviceProps      GPU address of the AllSpikingSynapsesDeviceProperties struct on device memory.
///  @param  numVertices                  Number of vertices.
///  @param  maxEdgesPerVertex        Maximum number of synapses per neuron.
void AllSpikingSynapses::copyHostToDevice( void* allEdgesDevice, AllSpikingSynapsesDeviceProperties& allEdgesDeviceProps, int numVertices, int maxEdgesPerVertex ) { // copy everything necessary 
        BGSIZE maxTotalSynapses = maxEdgesPerVertex * numVertices;

        allEdgesDeviceProps.maxEdgesPerVertex_ = maxEdgesPerVertex_;
        allEdgesDeviceProps.totalEdgeCount_ = totalEdgeCount_;
        allEdgesDeviceProps.countVertices_ = countVertices_;
        HANDLE_ERROR( cudaMemcpy ( allEdgesDevice, &allEdgesDeviceProps, sizeof( AllSpikingSynapsesDeviceProperties ), cudaMemcpyHostToDevice ) );

        // Set countVertices_ to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        allEdgesDeviceProps.countVertices_ = 0;

        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.sourceNeuronIndex_, sourceNeuronIndex_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.destNeuronIndex_, destNeuronIndex_,
                maxTotalSynapses * sizeof( int ),  cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.W_, W_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.type_, type_,
                maxTotalSynapses * sizeof( synapseType ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.psr_, psr_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.inUse_, inUse_,
                maxTotalSynapses * sizeof( bool ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.synapseCounts_, synapseCounts_,
                        numVertices * sizeof( BGSIZE ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.decay_, decay_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.tau_, tau_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.totalDelay_, totalDelay_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.delayQueue_, delayQueue_,
                maxTotalSynapses * sizeof( uint32_t ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.delayIndex_, delayIndex_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyHostToDevice ) );
        HANDLE_ERROR( cudaMemcpy ( allEdgesDeviceProps.delayQueueLength_, delayQueueLength_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyHostToDevice ) );
}

///  Copy all synapses' data from device to host.
///
///  @param  allEdgesDevice  GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                             on device memory.
void AllSpikingSynapses::copySynapseDeviceToHost( void* allEdgesDevice ) {
        // copy everything necessary
        AllSpikingSynapsesDeviceProperties allSynapses;

        HANDLE_ERROR( cudaMemcpy ( &allSynapses, allEdgesDevice, sizeof( AllSpikingSynapsesDeviceProperties ), cudaMemcpyDeviceToHost ) );

        copyDeviceToHost( allSynapses );
}

///  Copy all synapses' data from device to host.
///  (Helper function of copySynapseDeviceToHost)
///
///  @param  allEdgesDevice     GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                                on device memory.
///  @param  numVertices            Number of vertices.
///  @param  maxEdgesPerVertex  Maximum number of synapses per neuron.
void AllSpikingSynapses::copyDeviceToHost( AllSpikingSynapsesDeviceProperties& allEdgesDevice ) {
        int numVertices = Simulator::getInstance().getTotalVertices();
        BGSIZE maxTotalSynapses = Simulator::getInstance().getMaxSynapsesPerNeuron() * numVertices;

        HANDLE_ERROR( cudaMemcpy ( synapseCounts_, allEdgesDevice.synapseCounts_,
                numVertices * sizeof( BGSIZE ), cudaMemcpyDeviceToHost ) );
        maxEdgesPerVertex_ = allEdgesDevice.maxEdgesPerVertex_;
        totalEdgeCount_ = allEdgesDevice.totalEdgeCount_;
        countVertices_ = allEdgesDevice.countVertices_;

        // Set countVertices_ to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        allEdgesDevice.countVertices_ = 0;

        HANDLE_ERROR( cudaMemcpy ( sourceNeuronIndex_, allEdgesDevice.sourceNeuronIndex_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( destNeuronIndex_, allEdgesDevice.destNeuronIndex_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( W_, allEdgesDevice.W_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( type_, allEdgesDevice.type_,
                maxTotalSynapses * sizeof( synapseType ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( psr_, allEdgesDevice.psr_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( inUse_, allEdgesDevice.inUse_,
                maxTotalSynapses * sizeof( bool ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( decay_, allEdgesDevice.decay_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( tau_, allEdgesDevice.tau_,
                maxTotalSynapses * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( totalDelay_, allEdgesDevice.totalDelay_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( delayQueue_, allEdgesDevice.delayQueue_,
                maxTotalSynapses * sizeof( uint32_t ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( delayIndex_, allEdgesDevice.delayIndex_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( delayQueueLength_, allEdgesDevice.delayQueueLength_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
}

///  Get synapse_counts in AllEdges struct on device memory.
///
///  @param  allEdgesDevice  GPU address of the AllSpikingSynapsesDeviceProperties struct 
///                             on device memory.
void AllSpikingSynapses::copyDeviceSynapseCountsToHost( void* allEdgesDevice )
{
        AllSpikingSynapsesDeviceProperties allEdgesDeviceProps;
        int neuronCount = Simulator::getInstance().getTotalVertices();

        HANDLE_ERROR( cudaMemcpy ( &allEdgesDeviceProps, allEdgesDevice, sizeof( AllSpikingSynapsesDeviceProperties ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( synapseCounts_, allEdgesDeviceProps.synapseCounts_, neuronCount * sizeof( BGSIZE ), cudaMemcpyDeviceToHost ) );

        // Set countVertices_ to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        //allSynapses.countVertices_ = 0;
}

///  Get summationCoord and in_use in AllEdges struct on device memory.
///
///  @param  allEdgesDevice  GPU address of the AllSpikingSynapsesDeviceProperties struct
///                             on device memory.
void AllSpikingSynapses::copyDeviceSynapseSumIdxToHost(void* allEdgesDevice )
{
        AllSpikingSynapsesDeviceProperties allEdgesDeviceProps;
        BGSIZE maxTotalSynapses = Simulator::getInstance().getMaxSynapsesPerNeuron() * Simulator::getInstance().getTotalVertices();

        HANDLE_ERROR( cudaMemcpy ( &allEdgesDeviceProps, allEdgesDevice, sizeof( AllSpikingSynapsesDeviceProperties ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( sourceNeuronIndex_, allEdgesDeviceProps.sourceNeuronIndex_,
                maxTotalSynapses * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( inUse_, allEdgesDeviceProps.inUse_,
                maxTotalSynapses * sizeof( bool ), cudaMemcpyDeviceToHost ) );
       
        // Set countVertices_ to 0 to avoid illegal memory deallocation 
        // at AllSpikingSynapses deconstructor.
        //allSynapses.countVertices_ = 0;
}

///  Set some parameters used for advanceSynapsesDevice.
void AllSpikingSynapses::setAdvanceSynapsesDeviceParams()
{
    setEdgeClassID();
}

///  Set synapse class ID defined by enumClassSynapses for the caller's Synapse class.
///  The class ID will be set to classSynapses_d in device memory,
///  and the classSynapses_d will be referred to call a device function for the
///  particular synapse class.
///  Because we cannot use virtual function (Polymorphism) in device functions,
///  we use this scheme.
///  Note: we used to use a function pointer; however, it caused the growth_cuda crash
///  (see issue#137).
void AllSpikingSynapses::setEdgeClassID()
{
    enumClassSynapses classSynapses_h = classAllSpikingSynapses;

    HANDLE_ERROR( cudaMemcpyToSymbol( classSynapses_d, &classSynapses_h, sizeof(enumClassSynapses) ) );
}

///  Advance all the Synapses in the simulation.
///  Update the state of all synapses for a time step.
///
///  @param  allEdgesDevice      GPU address of the AllSynapsesDeviceProperties struct
///                                 on device memory.
///  @param  allVerticesDevice       GPU address of the allNeurons struct on device memory.
///  @param  synapseIndexMapDevice  GPU address of the EdgeIndexMap on device memory.
void AllSpikingSynapses::advanceEdges(void* allEdgesDevice, void* allVerticesDevice, void* synapseIndexMapDevice )
{
    if (totalEdgeCount_ == 0)
        return;

    // CUDA parameters
    const int threadsPerBlock = 256;
    int blocksPerGrid = ( totalEdgeCount_ + threadsPerBlock - 1 ) / threadsPerBlock;

    // Advance synapses ------------->
    advanceSpikingSynapsesDevice <<< blocksPerGrid, threadsPerBlock >>> ( totalEdgeCount_, (EdgeIndexMap*) synapseIndexMapDevice, g_simulationStep, Simulator::getInstance().getDeltaT(), (AllSpikingSynapsesDeviceProperties*)allEdgesDevice );
}

///  Prints GPU SynapsesProps data.
///   
///  @param  allEdgesDeviceProps   GPU address of the corresponding SynapsesDeviceProperties struct on device memory.
void AllSpikingSynapses::printGPUEdgesProps( void* allEdgesDeviceProps ) const
{
    AllSpikingSynapsesDeviceProperties allSynapsesProps;

    //allocate print out data members
    BGSIZE size = maxEdgesPerVertex_ * countVertices_;
    if (size != 0) {
        BGSIZE *synapseCountsPrint = new BGSIZE[countVertices_];
        BGSIZE maxSynapsesPerNeuronPrint;
        BGSIZE totalSynapseCountPrint;
        int countNeuronsPrint;
        int *sourceNeuronIndexPrint = new int[size];
        int *destNeuronIndexPrint = new int[size];
        BGFLOAT *WPrint = new BGFLOAT[size];

        synapseType *typePrint = new synapseType[size];
        BGFLOAT *psrPrint = new BGFLOAT[size];
        bool *inUsePrint = new bool[size];

        for (BGSIZE i = 0; i < size; i++) {
            inUsePrint[i] = false;
        }

        for (int i = 0; i < countVertices_; i++) {
            synapseCountsPrint[i] = 0;
        }

        BGFLOAT *decayPrint = new BGFLOAT[size];
        int *totalDelayPrint = new int[size];
        BGFLOAT *tauPrint = new BGFLOAT[size];


        // copy everything
        HANDLE_ERROR( cudaMemcpy ( &allSynapsesProps, allEdgesDeviceProps, sizeof( AllSpikingSynapsesDeviceProperties), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( synapseCountsPrint, allSynapsesProps.synapseCounts_, countVertices_ * sizeof( BGSIZE ), cudaMemcpyDeviceToHost ) );
        maxSynapsesPerNeuronPrint = allSynapsesProps.maxEdgesPerVertex_;
        totalSynapseCountPrint = allSynapsesProps.totalEdgeCount_;
        countNeuronsPrint = allSynapsesProps.countVertices_;

        // Set countVertices_ to 0 to avoid illegal memory deallocation
        // at AllSynapsesProps deconstructor.
        allSynapsesProps.countVertices_ = 0;

        HANDLE_ERROR( cudaMemcpy ( sourceNeuronIndexPrint, allSynapsesProps.sourceNeuronIndex_, size * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( destNeuronIndexPrint, allSynapsesProps.destNeuronIndex_, size * sizeof( int ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( WPrint, allSynapsesProps.W_, size * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( typePrint, allSynapsesProps.type_, size * sizeof( synapseType ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( psrPrint, allSynapsesProps.psr_, size * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( inUsePrint, allSynapsesProps.inUse_, size * sizeof( bool ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( decayPrint, allSynapsesProps.decay_, size * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( tauPrint, allSynapsesProps.tau_, size * sizeof( BGFLOAT ), cudaMemcpyDeviceToHost ) );
        HANDLE_ERROR( cudaMemcpy ( totalDelayPrint, allSynapsesProps.totalDelay_, size * sizeof( int ), cudaMemcpyDeviceToHost ) );


        for(int i = 0; i < maxEdgesPerVertex_ * countVertices_; i++) {
            if (WPrint[i] != 0.0) {
                cout << "GPU W[" << i << "] = " << WPrint[i];
                cout << " GPU sourNeuron: " << sourceNeuronIndexPrint[i];
                cout << " GPU desNeuron: " << destNeuronIndexPrint[i];
                cout << " GPU type: " << typePrint[i];
                cout << " GPU psr: " << psrPrint[i];
                cout << " GPU in_use:" << inUsePrint[i];

                cout << " GPU decay: " << decayPrint[i];
                cout << " GPU tau: " << tauPrint[i];
                cout << " GPU total_delay: " << totalDelayPrint[i] << endl;;
            }
        }

        for (int i = 0; i < countVertices_; i++) {
            cout << "GPU synapse_counts:" << "neuron[" << i  << "]" << synapseCountsPrint[i] << endl;
        }

        cout << "GPU totalSynapseCount:" << totalSynapseCountPrint << endl;
        cout << "GPU maxEdgesPerVertex:" << maxSynapsesPerNeuronPrint << endl;
        cout << "GPU countVertices_:" << countNeuronsPrint << endl;


        // Set countVertices_ to 0 to avoid illegal memory deallocation
        // at AllDSSynapsesProps deconstructor.
        allSynapsesProps.countVertices_ = 0;

        delete[] destNeuronIndexPrint;
        delete[] WPrint;
        delete[] sourceNeuronIndexPrint;
        delete[] psrPrint;
        delete[] typePrint;
        delete[] inUsePrint;
        delete[] synapseCountsPrint;
        destNeuronIndexPrint = NULL;
        WPrint = NULL;
        sourceNeuronIndexPrint = NULL;
        psrPrint = NULL;
        typePrint = NULL;
        inUsePrint = NULL;
        synapseCountsPrint = NULL;

        delete[] decayPrint;
        delete[] totalDelayPrint;
        delete[] tauPrint;
        decayPrint = NULL;
        totalDelayPrint = NULL;
        tauPrint = NULL;
    }
}

