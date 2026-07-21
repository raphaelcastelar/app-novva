import { isValidCnpj, isValidCpf, onlyDigits } from '../src/common/validation';

describe('Brazilian document validation', () => {
  it('normalizes punctuation', () => expect(onlyDigits('128.311.467-47')).toBe('12831146747'));
  it('accepts valid CPF and rejects invalid CPF', () => {
    expect(isValidCpf('12831146747')).toBe(true);
    expect(isValidCpf('11111111111')).toBe(false);
  });
  it('accepts valid CNPJ and rejects invalid CNPJ', () => {
    expect(isValidCnpj('11222333000181')).toBe(true);
    expect(isValidCnpj('00000000000000')).toBe(false);
  });
});
