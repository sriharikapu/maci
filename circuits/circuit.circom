include "./merkletree.circom";
include "./verify_eddsamimc.circom";
include "./decrypt.circom";

include "../node_modules/circomlib/circuits/mimc.circom";

template MACI(levels) {
  // levels is depth of tree
  
  // Output : new state tree root
  signal output new_state_tree_root;

  // Input(s)
  signal input cmd_tree_root;
  signal input cmd_tree_path_elements[levels];
  signal input cmd_tree_path_index[levels];

  signal input state_tree_root;
  signal private input state_tree_path_elements[levels];
  signal private input state_tree_path_index[levels];

  // Length of the encrypted data
  var data_length = 7;

  // Hashing rounds
  var rounds = 91;

  // NOTE: Last 3 elements in the arr
  // MUST BE THE SIGNATURE!
  /*
      [0] - iv (generated when msg is encrypted)
      [1] - publickey_x
      [2] - publickey_y
      [3] - action
      [4] - signature_r8x
      [5] - signature_r8y
      [6] - signature_s
   */
  signal input new_encrypted_data[data_length];
  signal input old_encrypted_data[data_length];

  // Shared private key
  signal private input new_ecdh_private_key;
  signal private input old_ecdh_private_key;

  // Construct leaf values
  component new_encrypted_data_hash = MultiMiMC7(data_length, rounds);
  for (var i = 0; i < data_length; i++) {
    new_encrypted_data_hash.in[i] <== new_encrypted_data[i];
  }

  component old_encrypted_data_hash = MultiMiMC7(data_length, rounds);
  for (var i = 0; i < data_length; i++) {
    old_encrypted_data_hash.in[i] <== old_encrypted_data[i];
  }

  // **** 1. Make sure the leaf exists in the cmd tree **** //
  component cmd_tree_value_exists = LeafExists(levels);
  cmd_tree_value_exists.root <== cmd_tree_root;
  cmd_tree_value_exists.leaf <== new_encrypted_data_hash.out;
  for (var i = 0; i < levels; i++) {
    cmd_tree_value_exists.path_elements[i] <== cmd_tree_path_elements[i];
    cmd_tree_value_exists.path_index[i] <== cmd_tree_path_index[i];
  }

  // **** 2. Make sure the state root hash is valid **** //
  component state_tree_valid = LeafExists(levels);
  state_tree_valid.root <== state_tree_root;
  state_tree_valid.leaf <== old_encrypted_data_hash.out;
  for (var i = 0; i < levels; i++) {
    state_tree_valid.path_elements[i] <== state_tree_path_elements[i];
    state_tree_valid.path_index[i] <== state_tree_path_index[i];
  }

  // **** 3.1 Decrypt data **** //
  component new_decrypted_data = Decrypt(data_length);
  new_decrypted_data.private_key <== new_ecdh_private_key;
  for (var i = 0; i < data_length; i++) {
    new_decrypted_data.message[i] <== new_encrypted_data[i];
  }

  component old_decrypted_data = Decrypt(data_length);
  old_decrypted_data.private_key <== old_ecdh_private_key;
  for (var i = 0; i < data_length; i++) {
    old_decrypted_data.message[i] <== old_encrypted_data[i];
  }

  // **** 3.2 Validate signature against old_encrypted_data **** //
  component signature_verifier = VerifyEdDSAMiMC(data_length - 3);

  signature_verifier.from_x <== old_decrypted_data.out[0]; // public key x
  signature_verifier.from_y <== old_decrypted_data.out[1]; // public key y

  signature_verifier.R8x <== new_decrypted_data.out[data_length - 3]; // sig R8x
  signature_verifier.R8y <== new_decrypted_data.out[data_length - 2]; // sig R8x
  signature_verifier.S <== new_decrypted_data.out[data_length - 1]; // sig S

  for (var i=0; i < data_length - 3; i++) {
    signature_verifier.preimage[i] <== new_decrypted_data.out[i];
  }

  // **** 4. If signature valid, update leaf **** //
  component new_state_tree = MerkleTreeUpdate(levels);
  new_state_tree.leaf <== new_encrypted_data_hash.out;
  for (var i = 0; i < levels; i++) {
    new_state_tree.path_elements[i] <== state_tree_path_elements[i];
    new_state_tree.path_index[i] <== state_tree_path_index[i];
  }

  new_state_tree_root <== new_state_tree.root;
}

component main = MACI(4);
