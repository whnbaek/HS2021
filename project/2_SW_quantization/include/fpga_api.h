#ifndef _FPGA_API_H_
#define _FPGA_API_H_
#include <sys/types.h>
#include <vector>
#include "compute.h"

// matrix vector multiplicator
// matrix M: M_SIZE by V_SIZE
// vector V: V_SIZE
// output = M * V

class FPGA
{

private:
  int fd_;

  // MV
  float *data_;

  char *qvec_;
  char *qmat_;

  int *qout_;

  float *out_;

  // MM
  float *data_M;

  char *qm1_;
  char *qm2_;
  char *qdata_M;

  int *qout_M;

  float *out_M;

  // others
  unsigned int *output_;

  int m_size_;
  int v_size_;
  int m1_size_;
  int m2_size_;

  int data_size_;
  int data_size_M;
  int num_block_call_;

public:
  FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size);
  ~FPGA();

  // return internal pointer for the data
  float *matrix(void);
  float *vector(void);
  float *matrix_M1(void);
  float *matrix_M2(void);

  char *qmatrix_M1(void);
  char *qmatrix_M2(void);
  char *qmatrix_Offset(void);
  int *qmatrix_Out(void);

  void reset(void);
  int num_block_call(void);

  // perform matrix multiplication and return output array pointer
  const float *blockMV(Compute* comp);
  const float *blockMM(Compute* comp);

  // Input vector size: num_input
  // Matrix size: num_output * num_input
  // Output vector size: num_output
  // O = M * I
  void largeMV(const float *mat, const float *input, float *output, int num_input, int num_output, Compute* comp);
  void largeMM(const float *mat, const float *input, float *output, int num_input, int num_output, int num_matrix, Compute* comp);
  void convLowering(const std::vector<std::vector<std::vector<std::vector<float>>>> &cnn_weights,
                    std::vector<std::vector<float>> &new_weights,
                    const std::vector<std::vector<std::vector<float>>> &inputs,
                    std::vector<std::vector<float>> &new_inputs);
};
#endif
