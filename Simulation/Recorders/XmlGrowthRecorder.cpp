/*
 *      @file XmlGrowthRecorder.cpp
 *
 *      @brief An implementation for recording spikes history on xml file
 */
//! An implementation for recording spikes history on xml file

#include "XmlGrowthRecorder.h"
#include "Simulator.h"
#include "Model.h"
#include "AllIFNeurons.h"      // TODO: remove LIF model specific code
#include "ConnGrowth.h"

//! THe constructor and destructor
XmlGrowthRecorder::XmlGrowthRecorder() :
      XmlRecorder(),
      ratesHistory(MATRIX_TYPE, MATRIX_INIT, static_cast<int>(Simulator::getInstance().getNumEpochs() + 1),
                   Simulator::getInstance().getTotalNeurons()),
      radiiHistory(MATRIX_TYPE, MATRIX_INIT, static_cast<int>(Simulator::getInstance().getNumEpochs() + 1),
                   Simulator::getInstance().getTotalNeurons()) {
}

XmlGrowthRecorder::~XmlGrowthRecorder() {
}

/*
 * Init radii and rates history matrices with default values
 */
void XmlGrowthRecorder::initDefaultValues() {
   shared_ptr<Connections> pConn = model_->getConnections();
   BGFLOAT startRadius = dynamic_cast<ConnGrowth *>(pConn.get())->m_growth.startRadius;

   for (int i = 0; i < Simulator::getInstance().getTotalNeurons(); i++) {
      radiiHistory(0, i) = startRadius;
      ratesHistory(0, i) = 0;
   }
}

/*
 * Init radii and rates history matrices with current radii and rates
 */
void XmlGrowthRecorder::initValues() {
   shared_ptr<Connections> pConn = model_->getConnections();

   for (int i = 0; i < Simulator::getInstance().getTotalNeurons(); i++) {
      radiiHistory(0, i) = (*dynamic_cast<ConnGrowth *>(pConn.get())->radii)[i];
      ratesHistory(0, i) = (*dynamic_cast<ConnGrowth *>(pConn.get())->rates)[i];
   }
}

/*
 * Get the current radii and rates values
 */
void XmlGrowthRecorder::getValues() {
   Connections *pConn = model_->getConnections().get();

   for (int i = 0; i < Simulator::getInstance().getTotalNeurons(); i++) {
      (*dynamic_cast<ConnGrowth *>(pConn)->radii)[i] = radiiHistory(Simulator::getInstance().getCurrentStep(), i);
      (*dynamic_cast<ConnGrowth *>(pConn)->rates)[i] = ratesHistory(Simulator::getInstance().getCurrentStep(), i);
   }
}

/*
 * Compile history information in every epoch
 *
 * @param[in] neurons 	The entire list of neurons.
 */
void XmlGrowthRecorder::compileHistories(IAllNeurons &neurons) {
   XmlRecorder::compileHistories(neurons);

   shared_ptr<Connections> pConn = model_->getConnections();

   BGFLOAT minRadius = dynamic_cast<ConnGrowth *>(pConn.get())->m_growth.minRadius;
   VectorMatrix &rates = (*dynamic_cast<ConnGrowth *>(pConn.get())->rates);
   VectorMatrix &radii = (*dynamic_cast<ConnGrowth *>(pConn.get())->radii);

   for (int iNeuron = 0; iNeuron < Simulator::getInstance().getTotalNeurons(); iNeuron++) {
      // record firing rate to history matrix
      ratesHistory(Simulator::getInstance().getCurrentStep(), iNeuron) = rates[iNeuron];

      // Cap minimum radius size and record radii to history matrix
      // TODO: find out why we cap this here.
      if (radii[iNeuron] < minRadius)
         radii[iNeuron] = minRadius;

      // record radius to history matrix
      radiiHistory(Simulator::getInstance().getCurrentStep(), iNeuron) = radii[iNeuron];

      DEBUG_MID(cout << "radii[" << iNeuron << ":" << radii[iNeuron] << "]" << endl;)
   }
}

/*
 * Writes simulation results to an output destination.
 *
 * @param  neurons the Neuron list to search from.
 **/
void XmlGrowthRecorder::saveSimData(const IAllNeurons &neurons) {
   // create Neuron Types matrix
   VectorMatrix neuronTypes(MATRIX_TYPE, MATRIX_INIT, 1, Simulator::getInstance().getTotalNeurons(), EXC);
   for (int i = 0; i < Simulator::getInstance().getTotalNeurons(); i++) {
      neuronTypes[i] = model_->getLayout()->neuron_type_map[i];
   }

   // create neuron threshold matrix
   VectorMatrix neuronThresh(MATRIX_TYPE, MATRIX_INIT, 1, Simulator::getInstance().getTotalNeurons(), 0);
   for (int i = 0; i < Simulator::getInstance().getTotalNeurons(); i++) {
      neuronThresh[i] = dynamic_cast<const AllIFNeurons &>(neurons).Vthresh_[i];
   }

   // Write XML header information:
   stateOut << "<?xml version=\"1.0\" standalone=\"no\"?>\n"
            << "<!-- State output file for the DCT growth modeling-->\n";
   //stateOut << version; TODO: version

   // Write the core state information:
   stateOut << "<SimState>\n";
   stateOut << "   " << radiiHistory.toXML("radiiHistory") << endl;
   stateOut << "   " << ratesHistory.toXML("ratesHistory") << endl;
   stateOut << "   " << burstinessHist.toXML("burstinessHist") << endl;
   stateOut << "   " << spikesHistory.toXML("spikesHistory") << endl;
   stateOut << "   " << model_->getLayout()->xloc->toXML("xloc") << endl;
   stateOut << "   " << model_->getLayout()->yloc->toXML("yloc") << endl;
   stateOut << "   " << neuronTypes.toXML("neuronTypes") << endl;

   // create starter nuerons matrix
   int num_starter_neurons = static_cast<int>(model_->getLayout()->num_endogenously_active_neurons);
   if (num_starter_neurons > 0) {
      VectorMatrix starterNeurons(MATRIX_TYPE, MATRIX_INIT, 1, num_starter_neurons);
      getStarterNeuronMatrix(starterNeurons, model_->getLayout()->starter_map);
      stateOut << "   " << starterNeurons.toXML("starterNeurons") << endl;
   }

   // Write neuron thresold
   stateOut << "   " << neuronThresh.toXML("neuronThresh") << endl;

   // write time between growth cycles
   stateOut << "   <Matrix name=\"Tsim\" type=\"complete\" rows=\"1\" columns=\"1\" multiplier=\"1.0\">" << endl;
   stateOut << "   " << Simulator::getInstance().getEpochDuration() << endl;
   stateOut << "</Matrix>" << endl;

   // write simulation end time
   stateOut << "   <Matrix name=\"simulationEndTime\" type=\"complete\" rows=\"1\" columns=\"1\" multiplier=\"1.0\">"
            << endl;
   stateOut << "   " << g_simulationStep * Simulator::getInstance().getDeltaT() << endl;
   stateOut << "</Matrix>" << endl;
   stateOut << "</SimState>" << endl;
}

