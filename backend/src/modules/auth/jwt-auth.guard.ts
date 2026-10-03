import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { PrismaService } from "../../common/prisma.service";

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
  ) {}
  async canActivate(context: ExecutionContext) {
    const request = context
      .switchToHttp()
      .getRequest<{ headers: { authorization?: string }; user?: unknown }>();
    const [type, token] = request.headers.authorization?.split(" ") ?? [];
    if (type !== "Bearer" || !token)
      throw new UnauthorizedException("Token de acesso ausente.");
    try {
      const payload = await this.jwt.verifyAsync<{
        sub?: string;
        id?: string;
        cpf?: string;
      }>(token);
      const userId = payload.sub ?? payload.id;
      if (!userId) throw new UnauthorizedException("Token de acesso inválido.");
      const user = await this.prisma.user.findFirst({
        where: { id: userId, status: "ACTIVE" },
        select: { id: true },
      });
      if (!user)
        throw new UnauthorizedException("Conta inexistente ou bloqueada.");
      request.user = payload;
      return true;
    } catch {
      throw new UnauthorizedException("Token de acesso inválido ou expirado.");
    }
  }
}
