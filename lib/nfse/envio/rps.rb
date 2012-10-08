require 'digest'

module Nfse
  module Envio
    class Rps < Base
      attr_accessor :numero, :situacao, :serie_rps_substituido,
        :num_rps_substituido, :num_nfe_substituida, :data_nfe_substituida,
        :cod_atividade, :aliquota_atividade, :tipo_recolhimento,
        :cod_municipio_prestacao, :municipio_prestacao, :operacao,
        :tributacao, :valor_pis, :valor_cofins, :valor_inss, :valor_ir,
        :valor_csll, :aliquota_pis, :aliquota_cofins, :aliquota_inss,
        :aliquota_ir, :aliquota_csll, :descricao, :motivo_cancelamento,
        :cnpj_intermediario

      attr_writer :tipo, :serie, :serie_prestacao
      attr_reader :prestador, :tomador, :itens, :deducoes

      def initialize(attributes = {})
        @prestador = Prestador.new(attributes.delete('prestador'))
        @tomador   = Tomador.new(attributes.delete('tomador'))
        @itens     = []
        @deducoes  = []

        _itens = attributes.delete('itens')
        _itens.each { |data| self.itens << Item.new(data) } if _itens.is_a? Array

        _deducoes = attributes.delete('deducoes')
        _deducoes.each { |data| self.deducoes << Deducao.new(data) } if _deducoes.is_a? Array

        super
      end

      def data_emissao
        @data_emissao ||= DateTime.now
      end

      # Atribui um valor para a data de emissao
      # rescue ArgumentError para quando for passado uma data inválida para o DateTime.parse
      def data_emissao=(value)
        @data_emissao = DateTime.parse(value.to_s)
      rescue ArgumentError
      end

      def tipo
        @tipo ||= 'RPS'
      end

      def serie
        @serie ||= 'NF'
      end

      def serie_prestacao
        @serie_prestacao ||= '99'
      end

      def assinatura
        Digest::SHA1.hexdigest(raw_signature)
      end

      # Soma do valor de todas as deducoes
      def valor_deducao
        deducoes.map{ |deducao| deducao.valor }.reduce(:+) || 0
      end

      # Soma do valor de todos os serviços
      def valor_servico
        itens.map{ |item| item.valor_total }.reduce(:+)
      end

      private
      def raw_signature
        deducao = valor_deducao
        valor_servico_com_deducao = valor_servico - deducao

        signature = prestador.inscricao_municipal.rjust(11, '0')
        signature << serie.ljust(5)
        signature << numero.rjust(12, '0')
        signature << data_emissao.strftime('%Y%m%d')
        signature << tributacao.ljust(2)
        signature << situacao
        signature << (tipo_recolhimento == 'A' ? 'N' : 'S')
        signature << valor_servico_com_deducao.to_s.rjust(15, '0')
        signature << deducao.to_s.rjust(15, '0')
        signature << cod_atividade.rjust(10, '0')
        signature << tomador.cnpj.rjust(14, '0')
      end
    end
  end
end
