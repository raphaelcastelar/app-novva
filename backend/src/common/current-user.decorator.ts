import { createParamDecorator, ExecutionContext } from '@nestjs/common';
export type AuthenticatedUser = { id: string; cpf: string };
export const CurrentUser = createParamDecorator((_data: unknown, context: ExecutionContext) =>
  context.switchToHttp().getRequest<{ user: AuthenticatedUser }>().user,
);
