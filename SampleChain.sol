// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// Cadena de custodia de muestras mineras. On-chain solo hashes, firmas y tiempos.
contract SampleChain is AccessControl {
    bytes32 public constant COLLECTOR = keccak256("COLLECTOR");
    bytes32 public constant TRANSPORTER = keccak256("TRANSPORTER");
    bytes32 public constant LAB = keccak256("LAB");

    enum Status { Created, InTransit, AtLab, Analyzed, Certified }
    enum Action { CREATED, TRANSPORTED, RECEIVED, PREPARED, ANALYZED, CERTIFIED }

    struct Sample {
        string mineralType;
        bytes32 metadataHash;
        address currentCustodian;
        Status status;
        uint64 createdAt;
        bool exists;
    }
    struct Event {
        Action action;
        address actor;
        address to;
        bytes32 evidenceHash;
        uint64 timestamp;
    }
    struct Certificate { bytes32 certHash; string uri; address lab; }

    mapping(bytes32 => Sample) public samples;
    mapping(bytes32 => Event[]) private _events;
    mapping(bytes32 => Certificate) public certificates;

    event SampleEvent(bytes32 indexed id, Action action, address indexed actor, address to, bytes32 evidenceHash);

    constructor() { _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); }

    function _log(bytes32 id, Action a, address to, bytes32 ev) private {
        _events[id].push(Event(a, msg.sender, to, ev, uint64(block.timestamp)));
        emit SampleEvent(id, a, msg.sender, to, ev);
    }

    modifier custodian(bytes32 id) {
        require(samples[id].exists, "Muestra inexistente");
        require(samples[id].currentCustodian == msg.sender, "No tiene la custodia");
        _;
    }

    function createSample(bytes32 id, string calldata mineralType, bytes32 metadataHash)
        external onlyRole(COLLECTOR)
    {
        require(!samples[id].exists, "La muestra ya existe");
        samples[id] = Sample(mineralType, metadataHash, msg.sender, Status.Created, uint64(block.timestamp), true);
        _log(id, Action.CREATED, msg.sender, metadataHash);
    }

    /// TRANSPORTED: recolector -> transportista. RECEIVED: transportista -> laboratorio.
    function transferCustody(bytes32 id, address to, Action action, bytes32 evidenceHash)
        external custodian(id)
    {
        Sample storage s = samples[id];
        if (action == Action.TRANSPORTED) {
            require(s.status == Status.Created && hasRole(COLLECTOR, msg.sender), "Paso invalido");
            require(hasRole(TRANSPORTER, to), "Destino no es transportista");
            s.status = Status.InTransit;
        } else if (action == Action.RECEIVED) {
            require(s.status == Status.InTransit && hasRole(TRANSPORTER, msg.sender), "Paso invalido");
            require(hasRole(LAB, to), "Destino no es laboratorio");
            s.status = Status.AtLab;
        } else revert("Accion no permitida");
        s.currentCustodian = to;
        _log(id, action, to, evidenceHash);
    }

    function recordStep(bytes32 id, Action action, bytes32 evidenceHash)
        external onlyRole(LAB) custodian(id)
    {
        Sample storage s = samples[id];
        require(s.status == Status.AtLab, "Paso invalido");
        if (action == Action.ANALYZED) s.status = Status.Analyzed;
        else require(action == Action.PREPARED, "Accion no permitida");
        _log(id, action, msg.sender, evidenceHash);
    }

    function certify(bytes32 id, bytes32 certHash, string calldata uri)
        external onlyRole(LAB) custodian(id)
    {
        Sample storage s = samples[id];
        require(s.status == Status.Analyzed, "Falta el analisis");
        s.status = Status.Certified;
        certificates[id] = Certificate(certHash, uri, msg.sender);
        _log(id, Action.CERTIFIED, msg.sender, certHash);
    }

    function getHistory(bytes32 id) external view returns (Event[] memory) { return _events[id]; }
}
