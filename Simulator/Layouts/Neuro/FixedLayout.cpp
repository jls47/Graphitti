/**
 * @file FixedLayout.cpp
 *
 * @ingroup Simulator/Layouts
 * 
 * @brief 
 */

#include "FixedLayout.h"
#include "ParseParamError.h"
#include "Util.h"

FixedLayout::FixedLayout() : Layout() {
}

FixedLayout::~FixedLayout() {
}

///  Prints out all parameters to logging file.
///  Registered to OperationManager as Operation::printParameters
void FixedLayout::printParameters() const {
   Layout::printParameters();

   LOG4CPLUS_DEBUG(fileLogger_, "\n\tLayout type: FixedLayout" << endl << endl);
}

///  Creates a randomly ordered distribution with the specified numbers of vertex types.
///
///  @param  numVertices number of the vertices to have in the type map.
void FixedLayout::generateVertexTypeMap(int numVertices) {
   Layout::generateVertexTypeMap(numVertices);

   int numInhibitoryNeurons = inhibitoryNeuronLayout_.size();
   int numExcititoryNeurons = numVertices - numInhibitoryNeurons;

   LOG4CPLUS_DEBUG(fileLogger_, "\nVERTEX TYPE MAP" << endl
   << "\tTotal vertices: " << numVertices << endl
   << "\tInhibitory Neurons: " << numInhibitoryNeurons << endl
   << "\tExcitatory Neurons: " << numExcititoryNeurons << endl);

   for (int i = 0; i < numInhibitoryNeurons; i++) {
      assert(inhibitoryNeuronLayout_.at(i) < numVertices);
      vertexTypeMap_[inhibitoryNeuronLayout_.at(i)] = INH;
   }

   LOG4CPLUS_INFO(fileLogger_, "Finished initializing vertex type map");
}

///  Populates the starter map.
///  Selects \e numStarter excitory neurons and converts them into starter neurons.
///  @param  numVertices number of vertices to have in the map.
void FixedLayout::initStarterMap(const int numVertices) {
   Layout::initStarterMap(numVertices);

   for (BGSIZE i = 0; i < numEndogenouslyActiveNeurons_; i++) {
      assert(endogenouslyActiveNeuronList_.at(i) < numVertices);
      starterMap_[endogenouslyActiveNeuronList_.at(i)] = true;
   }
}