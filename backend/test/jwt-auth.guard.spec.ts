import { UnauthorizedException } from "@nestjs/common";
import { JwtAuthGuard } from "../src/modules/auth/jwt-auth.guard";

function contextFor(authorization?: string) {
  const request = { headers: { authorization } };
  return {
    request,
    context: {
      switchToHttp: () => ({ getRequest: () => request }),
    } as any,
  };
}

describe("JwtAuthGuard", () => {
  it("accepts a valid token only when the user remains active", async () => {
    const jwt = {
      verifyAsync: jest.fn().mockResolvedValue({ sub: "user-id" }),
    };
    const prisma = {
      user: { findFirst: jest.fn().mockResolvedValue({ id: "user-id" }) },
    };
    const guard = new JwtAuthGuard(jwt as any, prisma as any);
    const { context, request } = contextFor("Bearer access-token");

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(prisma.user.findFirst).toHaveBeenCalledWith({
      where: { id: "user-id", status: "ACTIVE" },
      select: { id: true },
    });
    expect((request as any).user).toEqual({ sub: "user-id" });
  });

  it("rejects a token after the user is deleted or blocked", async () => {
    const jwt = {
      verifyAsync: jest.fn().mockResolvedValue({ sub: "user-id" }),
    };
    const prisma = { user: { findFirst: jest.fn().mockResolvedValue(null) } };
    const guard = new JwtAuthGuard(jwt as any, prisma as any);
    const { context } = contextFor("Bearer access-token");

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
