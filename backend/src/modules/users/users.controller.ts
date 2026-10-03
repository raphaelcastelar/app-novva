import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from "@nestjs/common";
import { ApiBearerAuth, ApiTags } from "@nestjs/swagger";
import {
  AuthenticatedUser,
  CurrentUser,
} from "../../common/current-user.decorator";
import { JwtAuthGuard } from "../auth/jwt-auth.guard";
import {
  CreateCnpjDto,
  DeleteAccountDto,
  UpdateCnpjDto,
  UpdateProfileDto,
  UpdateUserDto,
} from "./users.dto";
import { UsersService } from "./users.service";

@ApiTags("user")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class UsersController {
  constructor(private readonly service: UsersService) {}
  @Get("me") me(@CurrentUser() user: AuthenticatedUser) {
    return this.service.me(user.id);
  }
  @Patch("me") update(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateUserDto,
  ) {
    return this.service.update(user.id, dto);
  }
  @Delete("me") @HttpCode(204) remove(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: DeleteAccountDto,
  ) {
    return this.service.remove(user.id, dto.password);
  }
  @Get("medical-profile") profile(@CurrentUser() user: AuthenticatedUser) {
    return this.service.profile(user.id);
  }
  @Patch("medical-profile") updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.service.updateProfile(user.id, dto);
  }
  @Get("cnpjs") cnpjs(@CurrentUser() user: AuthenticatedUser) {
    return this.service.cnpjs(user.id);
  }
  @Post("cnpjs") createCnpj(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateCnpjDto,
  ) {
    return this.service.createCnpj(user.id, dto);
  }
  @Patch("cnpjs/:id") updateCnpj(
    @CurrentUser() user: AuthenticatedUser,
    @Param("id") id: string,
    @Body() dto: UpdateCnpjDto,
  ) {
    return this.service.updateCnpj(user.id, id, dto);
  }
  @Post("cnpjs/:id/activate") activateCnpj(
    @CurrentUser() user: AuthenticatedUser,
    @Param("id") id: string,
  ) {
    return this.service.activateCnpj(user.id, id);
  }
  @Delete("cnpjs/:id") @HttpCode(204) deleteCnpj(
    @CurrentUser() user: AuthenticatedUser,
    @Param("id") id: string,
  ) {
    return this.service.deleteCnpj(user.id, id);
  }
}
