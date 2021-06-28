#include "fpga_api.h"
#include <stdio.h>
#include <iostream>
#include <cstring>

using namespace std;

#define min(x, y) (((x) < (y)) ? (x) : (y))

FPGA::FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size)
{
  // MV
  m_size_ = m_size;
  v_size_ = v_size;
  data_size_ = (m_size_ + 1) * v_size_; // fpga bram data size

  data_ = new float[data_size_]; // initial input

  qvec_ = new char[v_size_]; // quantized vector
  qmat_ = new char[m_size_*v_size_]; // quantized matrix

  qout_ = new int[m_size_]; // quantized output

  out_ = new float[m_size_]; // final output

  m1_size_ = v_size * v_size;
  m2_size_ = v_size * v_size;
  data_size_M = (v_size_+v_size_)*v_size_;
  
  // MM
  data_M = new float[data_size_M]; // initial input

  qm1_ = new char[v_size_*v_size_]; // quantized matrix 1
  qm2_ = new char[v_size_*v_size_]; // quantized matrix 2
  
  qout_M = new int[v_size_*v_size_]; // quantized output matrix

  out_M = new float[v_size_*v_size_]; // final output matrix

  num_block_call_ = 0;
}

FPGA::~FPGA()
{
  delete[] data_;
  delete[] qvec_;
  delete[] qmat_;
  delete[] qout_;
  delete[] out_;

  delete[] data_M;
  delete[] qm1_;
  delete[] qm2_;
  delete[] qout_M;
  delete[] out_M;
}

float *FPGA::matrix(void)
{
  return data_ + v_size_;
}

float *FPGA::vector(void)
{
  return data_;
}

float *FPGA::matrix_M1(void)
{
  return data_M;
}

float *FPGA::matrix_M2(void)
{
  return data_M + m1_size_;
}

void FPGA::reset(void)
{
  num_block_call_ = 0;
}

int FPGA::num_block_call(void)
{
  return num_block_call_;
}

void quantize(const float* input, char* quantized, int num_input, int bits_min, int bits_max, char offset, float scale)
{
  for(int i = 0; i < num_input; i++) {
    int num = input[i] / scale + offset;
    quantized[i] = num < bits_min ? bits_min : (num > bits_max ? bits_max : num);
  }
}

void dequantize(int* quantized, float* output, int num_output, float scale)
{
  for(int i = 0; i < num_output; i++)
    output[i] = scale * quantized[i];
}

const float* FPGA::blockMM(Compute* comp)
{
  num_block_call_ += 1;

  // cpu version
  float* m1 = this->matrix_M1();
  float* m2 = this->matrix_M2();

  if(comp->quantized)
  {
    char act_bits_min = 0;
    char act_bits_max = (1<<(comp->act_bits-1))-1;

    float act_scale = (comp->act_max - comp->act_min) / 127.0;
    char act_offset = 127.0 * comp->act_min / (comp->act_min - comp->act_max);
    quantize(m2, qm2_, m2_size_, act_bits_min, act_bits_max, act_offset, act_scale);

    char weight_bits_min = 0;
    char weight_bits_max = (1<<(comp->weight_bits-1))-1;

    float weight_scale = (comp->weight_max - comp->weight_min) / 127.0;
    char weight_offset = 127.0 * comp->weight_min / (comp->weight_min - comp->weight_max);
    quantize(m1, qm1_, m1_size_, weight_bits_min, weight_bits_max, weight_offset, weight_scale);

    for(int i = 0; i < v_size_; ++i)
    {
      for(int j = 0; j < v_size_; ++j){    
        qout_M[v_size_*i+j] = 0;
        for(int k = 0; k < v_size_; ++k){
          qout_M[v_size_*i+j] += ((int)qm1_[v_size_*i+k] - weight_offset) * ((int)qm2_[v_size_*k + j] - act_offset);
        }
      }
    }
    dequantize(qout_M, out_M, m1_size_, act_scale * weight_scale);

  }
  else{
    for(int i = 0; i < v_size_; ++i)
    {
      for(int j = 0; j < v_size_; ++j){    
        out_M[v_size_*i+j] = 0;
        for(int k = 0; k < v_size_; ++k){
          out_M[v_size_*i+j] += m1[v_size_*i+k] * m2[v_size_*k + j];
        }
      }
    }
  }

  return out_M;
}

const float *FPGA::blockMV(Compute* comp)
{
  num_block_call_ += 1;

  // cpu version
  float *vec = this->vector();
  float *mat = this->matrix();

  if(comp->quantized)
  {
    char act_bits_min = 0;
    char act_bits_max = (1<<(comp->act_bits-1))-1;

    float act_scale = (comp->act_max - comp->act_min) / 127.0;
    char act_offset = 127.0 * comp->act_min / (comp->act_min - comp->act_max);
    quantize(vec, qvec_, v_size_, act_bits_min, act_bits_max, act_offset, act_scale);

    char weight_bits_min = 0;
    char weight_bits_max = (1<<(comp->weight_bits-1))-1;

    float weight_scale = (comp->weight_max - comp->weight_min) / 127.0;
    char weight_offset = 127.0 * comp->weight_min / (comp->weight_min - comp->weight_max);
    quantize(mat, qmat_, m_size_*v_size_, weight_bits_min, weight_bits_max, weight_offset, weight_scale);

    for (int i = 0; i < m_size_; ++i)
    {
      qout_[i] = 0;
      for (int j = 0; j < v_size_; ++j)
        qout_[i] += ((int)qvec_[j]-act_offset) * ((int)qmat_[v_size_ * i + j]-weight_offset);
    }

    dequantize(qout_, out_, m_size_, act_scale * weight_scale);
  }
  else
  {
    for (int i = 0; i < m_size_; ++i)
    {
      out_[i] = 0;
      for (int j = 0; j < v_size_; ++j)
        out_[i] += vec[j] * mat[v_size_ * i + j];
    }
  }

  return out_;
}

void FPGA::largeMM(const float* weight_mat, const float* input_mat, float* output, int num_input, int num_output, int num_matrix2, Compute* comp)
{
  float* m1 = this->matrix_M1();
  float* m2 = this->matrix_M2();

  // 0) Initialize output vector		
  for(int i = 0; i < num_output*num_matrix2; ++i)
    output[i] = 0;

  for(int i = 0; i < num_output; i += v_size_)
  {
    for(int j = 0; j < num_input; j += v_size_)
    {			
      for(int k = 0; k < num_matrix2; k += v_size_)
      {
        // 0) Initialize input vector
        int block_row = min(v_size_, num_output-i);
        int block_col_1 = min(v_size_, num_input-j);
        int block_col_2 = min(v_size_, num_matrix2-k);

        // 1) Assign a m1
        for (int l = 0; l < block_row; l++) {
          for (int m = 0; m < block_col_1; m++)
            m1[l * v_size_ + m] = weight_mat[(i + l) * num_input + (j + m)];
          for (int m = block_col_1; m < v_size_; m++)
            m1[l * v_size_ + m] = 0;
        }
        for (int l = block_row; l < v_size_; l++)
          for (int m = 0; m < v_size_; m++)
            m1[l * v_size_ + m] = 0;

        // 2) Assign a m2
        for (int l = 0; l < block_col_1; l++) {
          for (int m = 0; m < block_col_2; m++)
            m2[l * v_size_ + m] = input_mat[(j + l) * num_matrix2 + (k + m)];
          for (int m = block_col_2; m < v_size_; m++)
            m2[l * v_size_ + m] = 0;
        }
        for (int l = block_col_1; l < v_size_; l++)
          for (int m = 0; m < v_size_; m++)
            m2[l * v_size_ + m] = 0;

        // 3) Call a function `blockMM() to execute Matrix matrix multiplication
        const float* ret = this->blockMM(comp);

        // 4) Accumulate intermediate results
        for(int n = 0; n<block_row; ++n)
        {
          for(int m = 0; m<block_col_2; ++m)
          {
            output[(i + n) + (k + m)*num_output] += ret[n*v_size_ + m];
          }
        }
      }
    } 
  }
}

void FPGA::largeMV(const float *large_mat, const float *input, float *output, int num_input, int num_output, Compute* comp)
{
  float *vec = this->vector();
  float *mat = this->matrix();

  // 0) Initialize output vector
  for (int i = 0; i < num_output; ++i)
    output[i] = 0;

  for (int i = 0; i < num_output; i += m_size_)
  {
    for (int j = 0; j < num_input; j += v_size_)
    {
      // 0) Initialize input vector
      int block_row = min(m_size_, num_output - i);
      int block_col = min(v_size_, num_input - j);

      // 1) Assign a vector
      for(int k = 0; k < block_col; k++)
        vec[k] = input[j + k];
      for(int k = block_col; k < v_size_; k++)
        vec[k] = 0;

      // 2) Assign a matrix
      for(int k = 0; k < block_row; k++) {
        for(int l = 0; l < block_col; l++)
          mat[k * v_size_ + l] = large_mat[(i + k) * num_input + (j + l)];
        for(int l = block_col; l < v_size_; l++)
          mat[k * v_size_ + l] = 0;
      }
      for(int k = block_row; k < m_size_; k++)
        for(int l = 0; l < v_size_; l++)
          mat[k * v_size_ + l] = 0;

      // 3) Call a function `blockMV() to execute MV multiplication
      const float* ret = this->blockMV(comp);

      // 4) Accumulate intermediate results
      for (int row = 0; row < block_row; ++row)
        output[i + row] += ret[row];
    }
  }
}

void FPGA::convLowering(const std::vector<std::vector<std::vector<std::vector<float>>>> &cnn_weights,
                        std::vector<std::vector<float>> &new_weights,
                        const std::vector<std::vector<std::vector<float>>> &inputs,
                        std::vector<std::vector<float>> &new_inputs)
{
  /*
   * Arguments:
   *
   * conv_weights: [conv_channel, input_channel, conv_height, conv_width]
   * new_weights: [?, ?]
   * inputs: [input_channel, input_height, input_width]
   * new_inputs: [?, ?]
   *
   */

  int conv_channel = cnn_weights.size();
  int input_channel = cnn_weights[0].size();
  int conv_height = cnn_weights[0][0].size();
  int conv_width = cnn_weights[0][0][0].size();
  //int input_channel = inputs.size();
  int input_height = inputs[0].size();
  int input_width = inputs[0][0].size();

  // For example,
  // new_weights[0][0] = cnn_weights[0][0][0][0];
  // new_inputs[0][0] = inputs[0][0][0];

  int conv_size = conv_width * input_channel;
  int temp_height = input_height - conv_height + 1;
  int temp_width = input_width - conv_width + 1;

  for (int i = 0; i < conv_channel; i++)
    for (int j = 0; j < input_channel; j++)
      for (int k = 0; k < conv_height; k++)
        for (int l = 0; l < conv_width; l++)
          new_weights[i][j * conv_size + k * conv_width + l] = cnn_weights[i][j][k][l];

  for (int i = 0; i < input_channel; i++)
    for (int j = 0; j < conv_height; j++)
      for (int k = 0; k < conv_width; k++)
        for (int l = 0; l < temp_height; l++)
          for (int m = 0; m < temp_width; m++)
            new_inputs[i * conv_size + j * conv_width + k][l * temp_width + m] = inputs[i][j + l][k + m];
}
