import {
  DataSet,
  DataView,
  Network
} from "https://cdn.jsdelivr.net/npm/vis-network@8.3.2/dist/vis-network.esm.min.js";

fetch("/api/nodes")
  .then(function(resp) {
    return resp.json();
  })
  .then(function(data) {
    if (data.length === 0) {
      return;
    }

    // { id: 2, label: "Node 2" }
    const nodes = new DataSet(
      data.map(node => {
        node.label = node.title;
        return node;
      })
    );

    // { from: 2, to: 4 }
    const edges = new DataSet(
      data.map(node => ({
        from: node.id,
        to: node.parentId
      }))
    );

    const showingIds = new Set([data[0].id]);

    const nodesFilter = node => {
      return showingIds.has(node.id) || showingIds.has(node.parentId);
    };

    const nodesView = new DataView(nodes, { filter: nodesFilter });

    // create a network
    const container = document.getElementById("org-network");
    const netData = {
      nodes: nodesView,
      edges: edges
    };
    const options = {};
    const network = new Network(container, netData, options);

    network.on("click", e => {
      const { nodes } = e;
      for (const id of nodes) {
        if (showingIds.has(id)) showingIds.delete(id);
        else showingIds.add(id);
      }
      nodesView.refresh();
    });
  });
