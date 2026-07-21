import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';
const prisma = new PrismaClient();

async function main() {
  if (process.env.NODE_ENV === 'production' && process.env.ALLOW_PRODUCTION_SEED !== 'true') throw new Error('Seed de demonstração bloqueado em produção.');
  const passwordHash = await argon2.hash('Novva@1234', { type: argon2.argon2id });
  const user = await prisma.user.upsert({
    where: { cpf: '12831146747' },
    update: {},
    create: { cpf: '12831146747', name: 'Dra. Marina Almeida', email: 'marina@example.com', phone: '11999999999', passwordHash,
      profile: { create: { crm: 'CRM/SP 123456', specialty: 'Clínica médica', taxRegime: 'Simples Nacional', companyName: 'Marina Almeida Serviços Médicos' } } },
  });
  const cnpj = '11222333000181';
  await prisma.cnpj.upsert({ where: { userId_cnpj: { userId: user.id, cnpj } }, update: {}, create: { userId: user.id, cnpj, nickname: 'Consultório principal', companyName: 'Marina Almeida Serviços Médicos', active: true } });
  const count = await prisma.obligation.count({ where: { userId: user.id } });
  if (!count) {
    await prisma.obligation.createMany({ data: [
      { userId:user.id,name:'DAS Simples Nacional',kind:'DAS',dueDate:new Date('2026-07-20'),amount:1748.12,status:'DUE_SOON',paymentCode:'85890000017 48120385262 60720126052 00123456791' },
      { userId:user.id,name:'INSS pró-labore',kind:'INSS',dueDate:new Date('2026-07-25'),amount:642.10,status:'OPEN' },
    ]});
    await prisma.document.createMany({ data: [
      { userId:user.id,title:'Extrato bancário',category:'Extratos bancários',status:'PENDING',month:7,year:2026 },
      { userId:user.id,title:'Contrato social',category:'Contratos',status:'APPROVED',month:6,year:2026 },
    ]});
    await prisma.notification.create({ data: { userId:user.id,title:'Bem-vinda à Novva',body:'Seu ambiente está pronto para uso.',kind:'welcome' } });
  }
  console.log(`Usuário demo: ${user.cpf} / Novva@1234`);
}
main().finally(() => prisma.$disconnect());
